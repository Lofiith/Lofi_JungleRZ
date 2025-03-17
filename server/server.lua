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
end)


RegisterNetEvent("jungleRZ:playerExitedZone", function(zoneName)
    local src = source
    if playersInZone[src] == zoneName then
        playersInZone[src] = nil
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

-- im aware that this is not the best way to handle this
RegisterNetEvent("jungleRZ:requestAmbulanceRevive", function()
    local src = source
    local zoneName = playersInZone[src]
    if not zoneName then return end

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
    TriggerClientEvent('esx_ambulancejob:revive', src) -- change revive event name to match your ambulance script
end)

