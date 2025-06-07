local inZone = false
local currentZoneName = nil
local playerZoneStats = { kills = 0, headshots = 0, reward = 0 }

-- UI Functions
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
    playerZoneStats = { kills = 0, headshots = 0, reward = 0 }
end

-- Vehicle Enumeration
local function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, veh = FindFirstVehicle()
        if not veh or veh == 0 then
            EndFindVehicle(handle)
            return
        end
        local finished = false
        repeat
            coroutine.yield(veh)
            finished, veh = FindNextVehicle(handle)
        until not finished
        EndFindVehicle(handle)
    end)
end

-- Marker & Zone Drawing Thread
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

-- Blip Creation
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

-- Zone Detection Thread
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
            TriggerServerEvent("jungleRZ:playerEnteredZone")
            showUI()
            
            if Config.UseRoutingBuckets then
                SetPlayerRoutingBucket(PlayerId(), 1)
            end
        elseif not zoneFound and inZone then
            TriggerServerEvent("jungleRZ:playerExitedZone", currentZoneName)
            hideUI()
            inZone = false
            currentZoneName = nil
            
            if Config.UseRoutingBuckets then
                SetPlayerRoutingBucket(PlayerId(), 0)
            end
        end
        Wait(500)
    end
end)


-- Vehicle Deletion Thread 
if Config.DeleteVehiclesInZone then
    CreateThread(function()
        while true do
            for _, zone in ipairs(Config.Zones) do
                local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
                for veh in EnumerateVehicles() do
                    if #(GetEntityCoords(veh) - center) < zone.coords.w then
                        DeleteEntity(veh)
                    end
                end
            end
            Wait(1000)
        end
    end)
end

-- Death Handling Thread
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

-- Kill Detection
AddEventHandler("gameEventTriggered", function(eventName, data)
    if eventName == "CEventNetworkEntityDamage" then
        local victim = data[1]
        local attacker = data[2]
        
        if IsEntityDead(victim) then
            local attackerPlayer = NetworkGetPlayerIndexFromPed(attacker)
            if attackerPlayer == PlayerId() and currentZoneName then
                
                -- Only count player kills, not NPCs
                if not IsPedAPlayer(victim) then
                    return
                end
                
                -- Check cross-zone damage blocking
                if Config.BlockCrossZoneDamage then
                    local victimCoords = GetEntityCoords(victim)
                    local victimInSameZone = false
                    
                    for _, zone in ipairs(Config.Zones) do
                        if zone.name == currentZoneName then
                            local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
                            if #(victimCoords - center) < zone.coords.w then
                                victimInSameZone = true
                                break
                            end
                        end
                    end
                    
                    -- Only register kill if victim is in same zone
                    if not victimInSameZone then
                        return
                    end
                end
                
                TriggerServerEvent("jungleRZ:notifyKill", isHeadshot(victim))
            end
        end
    end
end)


if Config.BlockCrossZoneDamage then
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local players = GetActivePlayers()
            for _, player in ipairs(players) do
                if player ~= PlayerId() then
                    local otherPed = GetPlayerPed(player)
                    local otherCoords = GetEntityCoords(otherPed)
                    
                    -- Check if other player is in same zone as us
                    local otherInSameZone = false
                    if currentZoneName then
                        for _, zone in ipairs(Config.Zones) do
                            if zone.name == currentZoneName then
                                local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
                                if #(otherCoords - center) < zone.coords.w then
                                    otherInSameZone = true
                                    break
                                end
                            end
                        end
                    end
                    
                    -- If we're in a zone but they're not in the same zone, make them invincible to us
                    if currentZoneName and not otherInSameZone then
                        SetEntityInvincible(otherPed, true)
                    else
                        SetEntityInvincible(otherPed, false)
                    end
                end
            end
            Wait(1000)
        end
    end)
end

-- Update Stats
RegisterNetEvent("jungleRZ:updateStats", function(kills, headshots, reward)
    playerZoneStats = { kills = kills, headshots = headshots, reward = reward }
    SendNUIMessage({
        action = "updateUI",
        kills = kills,
        headshots = headshots,
        reward = reward
    })
end)
