Zones = Config.Zones
PlayerZoneData = {}

local function getZoneForPlayer(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local coords = GetEntityCoords(ped)
    for _, z in ipairs(Zones) do
        if #(coords - z.coords) <= z.radius then
            return z
        end
    end
    return nil
end

RegisterNetEvent('jungleRZ:enterZone')
AddEventHandler('jungleRZ:enterZone', function()
    local src = source
    local zone = getZoneForPlayer(src)
    if zone then
        PlayerZoneData[src] = { zone = zone, currentReward = zone.rewardStart or 0, kills = 0, headshots = 0 }
        for _, itemData in ipairs(zone.items) do
            TriggerEvent('jungleRZ:giveItem', itemData.name, itemData.amount)
        end
    end
end)

RegisterNetEvent('jungleRZ:exitZone')
AddEventHandler('jungleRZ:exitZone', function()
    local src = source
    local pdata = PlayerZoneData[src]
    if pdata then
        for _, itemData in ipairs(pdata.zone.items) do
            TriggerEvent('jungleRZ:removeItem', itemData.name, itemData.amount)
        end
        PlayerZoneData[src] = nil
    end
end)

RegisterNetEvent('jungleRZ:playerDied')
AddEventHandler('jungleRZ:playerDied', function(killerSrvId, isHS)
    local victim = source
    if killerSrvId and killerSrvId > 0 and killerSrvId ~= victim then
        local pdata = PlayerZoneData[killerSrvId]
        if pdata then
            pdata.kills = pdata.kills + 1
            if isHS then pdata.headshots = pdata.headshots + 1 end
            local moneyToGive = pdata.currentReward
            pdata.currentReward = pdata.currentReward + (pdata.zone.rewardIncrement or 0)
            TriggerEvent('jungleRZ:giveMoneyEvent', moneyToGive)
            TriggerClientEvent('jungleRZ:updateKillUI', killerSrvId, pdata.kills, pdata.headshots, pdata.currentReward)
        end
    end
    TriggerEvent('jungleRZ:onPlayerDeathServer', victim)
end)
