local playersInZone = {}
local playerZoneStats = {}
local lastKillTime = {}

-- Framework Handler Functions
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

-- Zone Entry Handler
RegisterNetEvent("jungleRZ:playerEnteredZone", function(zoneName)
    local src = source
    
    -- validation
    local validZone = false
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName then
            validZone = true
            break
        end
    end
    
    if not validZone or playersInZone[src] then
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

-- Zone Exit Handler
RegisterNetEvent("jungleRZ:playerExitedZone", function(zoneName)
    local src = source
    
    if playersInZone[src] == zoneName then
        handleZoneExit(src, zoneName)
        playersInZone[src] = nil
    end
    
    if playerZoneStats[src] and playerZoneStats[src][zoneName] then
        playerZoneStats[src][zoneName] = nil
    end
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0)
    end
end)

-- Kill Handler
RegisterNetEvent("jungleRZ:notifyKill", function(headshot)
    local src = source
    local now = GetGameTimer()
    
    -- rate limit
    if lastKillTime[src] and (now - lastKillTime[src]) < 500 then
        return
    end
    lastKillTime[src] = now
    
    local zoneName = playersInZone[src]
    if not zoneName or not playerZoneStats[src] or not playerZoneStats[src][zoneName] then
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

-- Ambulance Revive Handler
RegisterNetEvent("jungleRZ:requestAmbulanceRevive", function()
    local src = source
    local zoneName = playersInZone[src]
    if not zoneName then return end
    
    handleZoneExit(src, zoneName)
    
    if playerZoneStats[src] then
        playerZoneStats[src][zoneName] = nil
    end
    playersInZone[src] = nil
    
    local playerPed = GetPlayerPed(src)
    local exitPos = nil
    
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName then
            if type(zone.exitCoords) == "table" and #zone.exitCoords > 0 then
                exitPos = zone.exitCoords[math.random(#zone.exitCoords)]
            else
                exitPos = zone.exitCoords
            end
            break
        end
    end
    
    if not exitPos then
        exitPos = Config.DefaultRespawn
    end
    
    SetEntityCoords(playerPed, exitPos.x, exitPos.y, exitPos.z)
    SetEntityHeading(playerPed, exitPos.w or 0.0)
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0)
    end
    
    Wait(200)
    TriggerClientEvent('esx_ambulancejob:revive', src)
end)

-- Player Disconnect Handler
AddEventHandler('playerDropped', function(reason)
    local src = source
    local zoneName = playersInZone[src]
    
    if zoneName then
        handleZoneExit(src, zoneName)
    end
    
    playersInZone[src] = nil
    playerZoneStats[src] = nil
    lastKillTime[src] = nil
end)
