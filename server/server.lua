local playersInZone = {}
local playerZoneStats = {}
local killTimestamps = {}  -- table mapping source -> list of timestamps for kill events

-- Utility function to calculate Euclidean distance between two points
local function getDistance(coords1, coords2)
    local dx = coords1.x - coords2.x
    local dy = coords1.y - coords2.y
    local dz = coords1.z - coords2.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Utility function to record a kill event for rate limiting.
-- Allows up to maxKills within interval seconds.
local function recordKillEvent(src, interval, maxKills)
    local now = os.time()
    if not killTimestamps[src] then
        killTimestamps[src] = {}
    end

    -- Remove outdated timestamps
    local recent = {}
    for _, t in ipairs(killTimestamps[src]) do
        if now - t < interval then
            table.insert(recent, t)
        end
    end
    killTimestamps[src] = recent

    if #recent >= maxKills then
        print(string.format("Potential Modder: Kill event from player %s rate-limited (received %d events in %d seconds)", src, #recent + 1, interval))
        return false
    end

    table.insert(killTimestamps[src], now)
    return true
end

RegisterNetEvent("jungleRZ:playerEnteredZone", function(zoneName, playerCoords)
    local src = source
    local validZone = false

    -- Validate player's coordinates against the zone boundaries
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName then
            local distance = getDistance(playerCoords, { x = z.coords.x, y = z.coords.y, z = z.coords.z })
            if distance <= z.coords.w then
                validZone = true
            end
            break
        end
    end

    if not validZone then
        print(string.format("Potential Modder: Player %s attempted to enter invalid zone '%s' with coords: x=%.2f, y=%.2f, z=%.2f", src, zoneName, playerCoords.x, playerCoords.y, playerCoords.z))
        return
    end

    playersInZone[src] = zoneName

    if not playerZoneStats[src] then
        playerZoneStats[src] = {}
    end

    if not playerZoneStats[src][zoneName] then
        for _, z in ipairs(Config.Zones) do
            if z.name == zoneName then
                playerZoneStats[src][zoneName] = {
                    kills = 0,
                    headshots = 0,
                    currentReward = z.startingReward,
                    rewardIncrement = z.rewardIncrement
                }
                break
            end
        end
    end

    local stats = playerZoneStats[src][zoneName]
    TriggerClientEvent("jungleRZ:updateStats", src, stats.kills, stats.headshots, stats.currentReward)
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 1) -- Place player in the "inside" bucket
    end
end)

RegisterNetEvent("jungleRZ:playerExitedZone", function(zoneName)
    local src = source
    if playersInZone[src] == zoneName then
        playersInZone[src] = nil
    end
    if playerZoneStats[src] and playerZoneStats[src][zoneName] then
        playerZoneStats[src][zoneName] = nil
    end

    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0) -- Revert to default bucket
    end
end)

RegisterNetEvent("jungleRZ:notifyKill", function(headshot, playerCoords)
    local src = source

    -- Allow up to 2 kill events every 2 seconds
    if not recordKillEvent(src, 2, 2) then
        return
    end

    local zoneName = playersInZone[src]
    if not zoneName then return end

    -- Verify provided coordinates fall within the player's current zone
    local validZone = false
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName then
            local distance = getDistance(playerCoords, { x = z.coords.x, y = z.coords.y, z = z.coords.z })
            if distance <= z.coords.w then
                validZone = true
            end
            break
        end
    end

    if not validZone then
        print(string.format("Potential Modder: Player %s kill event invalid - reported coordinates not within zone '%s' boundaries", src, zoneName))
        return
    end

    if not playerZoneStats[src] then return end
    if not playerZoneStats[src][zoneName] then return end

    local stats = playerZoneStats[src][zoneName]
    stats.kills = stats.kills + 1
    if headshot then
        stats.headshots = stats.headshots + 1
    end

    local reward = stats.currentReward
    if reward < 0 then reward = 0 end
    
    -- Award reward using the appropriate framework
    if Config.Framework == "ox" then
        local success = exports.ox_inventory:AddItem(src, 'money', reward)
        if not success then return end
    elseif Config.Framework == "esx" then
        if ESX then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                xPlayer.addMoney(reward)
            end
        end
    elseif Config.Framework == "qbcore" then
        if QBCore and QBCore.Functions then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                Player.Functions.AddMoney("cash", reward, "redzone-kill")
            end
        end
    end

    TriggerClientEvent("jungleRZ:updateStats", src, stats.kills, stats.headshots, reward)
    stats.currentReward = stats.currentReward + stats.rewardIncrement
end)

RegisterNetEvent("jungleRZ:enterZoneBucket", function(zoneName)
    local src = source
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 1)
    end
end)

RegisterNetEvent("jungleRZ:exitZoneBucket", function()
    local src = source
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0)
    end
end)

RegisterNetEvent("jungleRZ:requestAmbulanceRevive", function()
    local src = source
    local zoneName = playersInZone[src]
    if not zoneName then return end

    if playerZoneStats[src] then
        playerZoneStats[src][zoneName] = nil
    end
    playersInZone[src] = nil

    local playerPed = GetPlayerPed(src)
    if GetEntityHealth(playerPed) > 0 then
        return
    end

    local exitPos, heading = nil, 0.0
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName then
            if type(z.exitCoords) == "table" and #z.exitCoords > 0 then
                exitPos = z.exitCoords[math.random(#z.exitCoords)]
            else
                exitPos = z.exitCoords
            end
            break
        end
    end

    if not exitPos then
        exitPos = Config.DefaultRespawn
    end
    heading = exitPos.w or 0.0
    SetEntityCoords(playerPed, exitPos.x, exitPos.y, exitPos.z)
    SetEntityHeading(playerPed, heading)
    Wait(200)
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0)
    end
    
    TriggerClientEvent('esx_ambulancejob:revive', src)
end)
