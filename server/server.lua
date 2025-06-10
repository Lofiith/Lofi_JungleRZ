local playersInZone = {}
local playerZoneStats = {}
local lastKillTime = {}
local zoneEntryTime = {}

CreateThread(function()
    if Config.DeleteVehiclesInZone then
        for _, zone in ipairs(Config.Zones) do
            local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
            local vehicles = GetAllVehicles()
            for _, veh in ipairs(vehicles) do
                local vehCoords = GetEntityCoords(veh)
                if #(vehCoords - center) < zone.coords.w then
                    DeleteEntity(veh)
                end
            end
        end
    end
end)

local function validatePlayerInZone(src, zoneName)
    if not zoneName then return false end
    
    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 then return false end
    
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName then
            local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
            local distance = #(playerCoords - center)
            return distance <= zone.coords.w
        end
    end
    return false
end

local function handleZoneEntry(src, zoneName)
    if Config.Framework == "esx" then
        ESXHandleZoneEntry(src, zoneName)
    elseif Config.Framework == "qbcore" then
        QBHandleZoneEntry(src, zoneName)
    elseif Config.Framework == "ox" then
        OXHandleZoneEntry(src, zoneName)
    end
end

local function handleZoneExit(src, zoneName)
    if Config.Framework == "esx" then
        ESXHandleZoneExit(src, zoneName)
    elseif Config.Framework == "qbcore" then
        QBHandleZoneExit(src, zoneName)
    elseif Config.Framework == "ox" then
        OXHandleZoneExit(src, zoneName)
    end
end

local function giveReward(src, amount)
    if Config.Framework == "esx" then
        ESXGiveReward(src, amount)
    elseif Config.Framework == "qbcore" then
        QBGiveReward(src, amount)
    elseif Config.Framework == "ox" then
        OXGiveReward(src, amount)
    end
end

RegisterNetEvent("jungleRZ:deleteVehicle", function(netId)
    local src = source
    if not playersInZone[src] then return end
    
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end)

RegisterNetEvent("jungleRZ:playerEnteredZone", function(zoneName)
    local src = source
    local now = GetGameTimer()
    
    if zoneEntryTime[src] and (now - zoneEntryTime[src]) < 2000 then
        return
    end
    zoneEntryTime[src] = now
    
    if not validatePlayerInZone(src, zoneName) then
        return
    end
    
    if playersInZone[src] then
        return
    end
    
    playersInZone[src] = zoneName
    
    if not playerZoneStats[src] then
        playerZoneStats[src] = {}
    end
    
    if not playerZoneStats[src][zoneName] then
        for _, zone in ipairs(Config.Zones) do
            if zone.name == zoneName then
                playerZoneStats[src][zoneName] = {
                    kills = 0,
                    headshots = 0,
                    currentReward = zone.startingReward,
                    rewardIncrement = zone.rewardIncrement
                }
                break
            end
        end
    end
    
    local stats = playerZoneStats[src][zoneName]
    TriggerClientEvent("jungleRZ:updateStats", src, stats.kills, stats.headshots, stats.currentReward)
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 1)
    end
    
    handleZoneEntry(src, zoneName)
end)

RegisterNetEvent("jungleRZ:playerExitedZone", function(zoneName)
    local src = source
    
    if playersInZone[src] ~= zoneName then
        return
    end
    
    handleZoneExit(src, zoneName)
    playersInZone[src] = nil
    
    if playerZoneStats[src] and playerZoneStats[src][zoneName] then
        playerZoneStats[src][zoneName] = nil
    end
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0)
    end
end)

RegisterNetEvent("jungleRZ:notifyKill", function(zoneName, headshot)
    local src = source
    local now = GetGameTimer()
    
    if lastKillTime[src] and (now - lastKillTime[src]) < 1000 then
        return
    end
    lastKillTime[src] = now
    
    if playersInZone[src] ~= zoneName then
        return
    end
    
    if not validatePlayerInZone(src, zoneName) then
        return
    end
    
    if not playerZoneStats[src] or not playerZoneStats[src][zoneName] then
        return
    end
    
    local stats = playerZoneStats[src][zoneName]
    stats.kills = stats.kills + 1
    if headshot then
        stats.headshots = stats.headshots + 1
    end
    
    local reward = math.max(0, stats.currentReward)
    giveReward(src, reward)
    
    TriggerClientEvent("jungleRZ:updateStats", src, stats.kills, stats.headshots, reward)
    stats.currentReward = stats.currentReward + stats.rewardIncrement
end)

RegisterNetEvent("jungleRZ:requestAmbulanceRevive", function(passedZoneName)
    local src = source
    
    local zoneName = passedZoneName or playersInZone[src]
    if not zoneName then
        return
    end
    
    local exitPos = nil
    local zoneData = nil
    
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName then
            zoneData = zone
            if type(zone.exitCoords) == "table" and #zone.exitCoords > 0 then
                exitPos = zone.exitCoords[math.random(#zone.exitCoords)]
            else
                exitPos = zone.exitCoords
            end
            break
        end
    end
    
    if not exitPos then
        return
    end
    
    if playersInZone[src] then
        handleZoneExit(src, zoneName)
        playersInZone[src] = nil
    end
    
    if playerZoneStats[src] and playerZoneStats[src][zoneName] then
        playerZoneStats[src][zoneName] = nil
    end
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0)
    end
    
    local playerPed = GetPlayerPed(src)
    SetEntityCoords(playerPed, exitPos.x, exitPos.y, exitPos.z)
    SetEntityHeading(playerPed, exitPos.w or 0.0)
    
    CreateThread(function()
        Wait(500)
        TriggerClientEvent('esx_ambulancejob:revive', src)
        TriggerClientEvent("jungleRZ:handleRevive", src)
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local zoneName = playersInZone[src]
    
    if zoneName then
        handleZoneExit(src, zoneName)
    end
    
    playersInZone[src] = nil
    playerZoneStats[src] = nil
    lastKillTime[src] = nil
    zoneEntryTime[src] = nil
end)
