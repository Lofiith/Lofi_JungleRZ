local api = require 'client.api'
local inZone = false
local currentZoneName = nil
local playerZoneStats = { kills = 0, headshots = 0, reward = 0 }

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

CreateThread(function()
    while true do
        local ped = cache.ped
        local coords = GetEntityCoords(ped)
        local waitTime = 500
        
        for _, zone in ipairs(Config.Zones) do
            local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
            if #(coords - center) < (zone.coords.w + Config.MarkerDrawDistance) then
                waitTime = 0
                api.DrawMarker(zone.coords, zone.coords.w, Config.MarkerColor)
            end
        end
        Wait(waitTime)
    end
end)

if Config.EnableBlip then
    CreateThread(function()
        for _, zone in ipairs(Config.Zones) do
            api.AddBlip(zone.coords, Config.ZoneBlipIcon, Config.ZoneBlipIconScale, Config.ZoneBlipIconColor, zone.name, true)
            api.AddRadiusBlip(zone.coords, zone.coords.w, 1, 128)
        end
    end)
end

CreateThread(function()
    while true do
        local ped = cache.ped
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
            
            if cache.vehicle and Config.DeleteVehiclesInZone then
                TriggerServerEvent("jungleRZ:deleteVehicle", NetworkGetNetworkIdFromEntity(cache.vehicle))
            end
            
            TriggerServerEvent("jungleRZ:playerEnteredZone", zoneFound)
            showUI()
        elseif not zoneFound and inZone then
            TriggerServerEvent("jungleRZ:playerExitedZone", currentZoneName)
            hideUI()
            inZone = false
            currentZoneName = nil
        end
        Wait(500)
    end
end)

CreateThread(function()
    local isDead = false
    while true do
        local ped = cache.ped
        
        if IsEntityDead(ped) then
            if not isDead and inZone and currentZoneName then
                isDead = true
                TriggerServerEvent("jungleRZ:requestAmbulanceRevive", currentZoneName)
            end
        else
            isDead = false
        end
        
        Wait(100)
    end
end)

local function isHeadshot(victim)
    local boneIndex = GetPedLastDamageBone(victim)
    return (boneIndex == 31086)
end

AddEventHandler("gameEventTriggered", function(eventName, data)
    if eventName == "CEventNetworkEntityDamage" then
        local victim = data[1]
        local attacker = data[2]
        
        if IsEntityDead(victim) then
            local attackerPlayer = NetworkGetPlayerIndexFromPed(attacker)
            if attackerPlayer == PlayerId() and currentZoneName then
                
                if not IsPedAPlayer(victim) then
                    return
                end
                
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
                    
                    if not victimInSameZone then
                        return
                    end
                end
                
                TriggerServerEvent("jungleRZ:notifyKill", currentZoneName, isHeadshot(victim))
            end
        end
    end
end)

if Config.BlockCrossZoneDamage then
    CreateThread(function()
        while true do
            local ped = cache.ped
            local players = GetActivePlayers()
            for _, player in ipairs(players) do
                if player ~= PlayerId() then
                    local otherPed = GetPlayerPed(player)
                    local otherCoords = GetEntityCoords(otherPed)
                    
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

RegisterNetEvent("jungleRZ:updateStats", function(kills, headshots, reward)
    if source ~= '' then return end
    playerZoneStats = { kills = kills, headshots = headshots, reward = reward }
    SendNUIMessage({
        action = "updateUI",
        kills = kills,
        headshots = headshots,
        reward = reward
    })
end)

RegisterNetEvent("jungleRZ:handleRevive", function()
    if source ~= '' then return end
    if inZone then
        hideUI()
        inZone = false
        currentZoneName = nil
    end
end)
