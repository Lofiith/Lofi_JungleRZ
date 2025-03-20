local playersInZone = {}
local playerZoneStats = {}

RegisterNetEvent("jungleRZ:playerEnteredZone", function(zoneName)
    local src = source
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
    
    -- Also update routing bucket if enabled (redundant if client called separate event)
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 1) -- inside bucket
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
        SetPlayerRoutingBucket(src, 0) -- revert to default bucket
    end
end)

RegisterNetEvent("jungleRZ:notifyKill", function(headshot)
    local src = source
    local zoneName = playersInZone[src]
    if not zoneName then return end
    if not playerZoneStats[src] then return end
    if not playerZoneStats[src][zoneName] then return end

    local stats = playerZoneStats[src][zoneName]
    stats.kills = stats.kills + 1
    if headshot then
        stats.headshots = stats.headshots + 1
    end

    local reward = stats.currentReward
    if reward < 0 then reward = 0 end
    
    -- yes this stuff shouldve be added framework specific :/
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

-- Routing bucket events
RegisterNetEvent("jungleRZ:enterZoneBucket", function(zoneName)
    local src = source
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 1) -- inside bucket
    end
end)

RegisterNetEvent("jungleRZ:exitZoneBucket", function()
    local src = source
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0) -- default outside bucket
    end
end)

-- Revive handling
RegisterNetEvent("jungleRZ:requestAmbulanceRevive", function()
    local src = source
    local zoneName = playersInZone[src]
    if not zoneName then return end

    -- Reset the player's stats for the current zone
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
    
    -- Reset bucket to default upon revive
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0)
    end
    
    TriggerClientEvent('esx_ambulancejob:revive', src)
end)
