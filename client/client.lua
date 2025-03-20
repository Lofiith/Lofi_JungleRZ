local inZone = false
local currentZoneName = nil

-- UI
local function setUIPosition()
    SendNUIMessage({ action = "setUIPosition", position = Config.UIPosition })
end

local function showUI()
    setUIPosition()
    SendNUIMessage({ action = "showUI" })
end

local function hideUI()
    SendNUIMessage({ action = "hideUI" })
    SendNUIMessage({ action = "resetUI", kills = 0, headshots = 0, reward = 0 })
end

-- Marker + Zone Detection
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local waitTime = 500

        for _, zone in ipairs(Config.Zones) do
            local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
            if #(coords - center) < (zone.coords.w + Config.MarkerDrawDistance) then
                waitTime = 0
                DrawMarker(
                    28,
                    zone.coords.x, zone.coords.y, zone.coords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    zone.coords.w, zone.coords.w, zone.coords.w,
                    Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a,
                    false, true, 2, false, nil, nil, false
                )
            end
        end

        Wait(waitTime)
    end
end)

if Config.EnableBlip then
    CreateThread(function()
        for _, zone in ipairs(Config.Zones) do
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(blip, Config.ZoneBlipIcon)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.ZoneBlipIconScale)
            SetBlipColour(blip, Config.ZoneBlipIconColor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(zone.name)
            EndTextCommandSetBlipName(blip)
            local radiusBlip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.coords.w)
            SetBlipColour(radiusBlip, 1)
            SetBlipAlpha(radiusBlip, 128) 
        end
    end)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local zoneFound = nil

        for _, zone in ipairs(Config.Zones) do
            if #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z)) < zone.coords.w then
                zoneFound = zone.name
                break
            end
        end

        if zoneFound and not inZone then
            inZone = true
            currentZoneName = zoneFound
            TriggerServerEvent("jungleRZ:playerEnteredZone", zoneFound)
            showUI()
            if Config.UseRoutingBuckets then
                TriggerServerEvent("jungleRZ:enterZoneBucket", zoneFound)
            end
        elseif not zoneFound and inZone then
            TriggerServerEvent("jungleRZ:playerExitedZone", currentZoneName)
            hideUI()
            inZone = false
            currentZoneName = nil
            if Config.UseRoutingBuckets then
                TriggerServerEvent("jungleRZ:exitZoneBucket")
            end
        end

        Wait(500)
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsEntityDead(ped) and currentZoneName then
            TriggerServerEvent("jungleRZ:requestAmbulanceRevive")
            repeat
                Wait(500)
            until not IsEntityDead(ped)
        end
        Wait(500)
    end
end)

-- Kill Detection
local function isHeadshot(victim)
    local boneIndex = GetPedLastDamageBone(victim)
    return (boneIndex == 31086)
end

AddEventHandler("gameEventTriggered", function(eventName, data)
    if eventName == "CEventNetworkEntityDamage" then
        local victim = data[1]
        local attacker = data[2]
        if IsEntityDead(victim) then
            -- Block cross-zone damage if enabled
            if Config.BlockCrossZoneDamage then
                local attackerZone = currentZoneName  -- attacker’s zone (nil if outside)
                local victimCoords = GetEntityCoords(victim)
                local victimZone = nil
                for _, zone in ipairs(Config.Zones) do
                    if #(victimCoords - vector3(zone.coords.x, zone.coords.y, zone.coords.z)) < zone.coords.w then
                        victimZone = zone.name
                        break
                    end
                end
                if attackerZone ~= victimZone then
                    return  -- do not process kill if they are not in the same zone
                end
            end

            local attackerPlayer = NetworkGetPlayerIndexFromPed(attacker)
            if attackerPlayer == PlayerId() and currentZoneName then
                TriggerServerEvent("jungleRZ:notifyKill", isHeadshot(victim))
            end
        end
    end
end)

-- Update Stats from Server
RegisterNetEvent("jungleRZ:updateStats", function(kills, headshots, reward)
    SendNUIMessage({
        action = "updateUI",
        kills = kills,
        headshots = headshots,
        reward = reward
    })
end)
