local playersInZone = {}
local playerZoneStats = {}
local lastKillTime = {}
local zoneEntryTime = {}

-- validation function
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
    local now = GetGameTimer()
    
    -- (prevent spam)
    if zoneEntryTime[src] and (now - zoneEntryTime[src]) < 2000 then
        return
    end
    zoneEntryTime[src] = now
    
    -- check if player is actually in the zone
    if not validatePlayerInZone(src, zoneName) then
        return
    end
    
    -- Prevent duplicate entries
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

-- Zone Exit Handler
RegisterNetEvent("jungleRZ:playerExitedZone", function(zoneName)
    local src = source
    
    -- Only allow exit if player was actually in the zone
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

-- Kill Handler
RegisterNetEvent("jungleRZ:notifyKill", function(headshot)
    local src = source
    local now = GetGameTimer()
    
    -- (max 1 kill per second)
    if lastKillTime[src] and (now - lastKillTime[src]) < 1000 then
        return
    end
    lastKillTime[src] = now
    
    local zoneName = playersInZone[src]
    if not zoneName then
        return
    end
    
    -- ensure player is still in zone
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


-- Revive Handler
RegisterNetEvent("jungleRZ:requestAmbulanceRevive", function()
    local src = source
    
    local zoneName = playersInZone[src]
    if not zoneName then
        return
    end
    
    -- Verify player is actually dead
    local playerPed = GetPlayerPed(src)
    if not IsEntityDead(playerPed) then
        return
    end
    
    handleZoneExit(src, zoneName)
    
    if playerZoneStats[src] then
        playerZoneStats[src][zoneName] = nil
    end
    playersInZone[src] = nil
    
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
        return
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
    zoneEntryTime[src] = nil
end)
