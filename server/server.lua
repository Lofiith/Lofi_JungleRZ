local Zones = Config.Zones

local function inZone(src, zoneName)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    for _, z in ipairs(Zones) do
        if z.name == zoneName then
            if #(coords - z.coords) <= z.radius then
                return true
            end
        end
    end
    return false
end

RegisterNetEvent('jungleRZ:enterZone')
AddEventHandler('jungleRZ:enterZone', function(zoneName)
    local src = source
    if inZone(src, zoneName) then
        for _, z in ipairs(Zones) do
            if z.name == zoneName then
                for _, itemData in ipairs(z.items) do
                    TriggerEvent('jungleRZ:giveItem', src, itemData.name, itemData.amount)
                end
            end
        end
    end
end)

RegisterNetEvent('jungleRZ:exitZone')
AddEventHandler('jungleRZ:exitZone', function(zoneName)
    local src = source
    for _, z in ipairs(Zones) do
        if z.name == zoneName then
            for _, itemData in ipairs(z.items) do
                TriggerEvent('jungleRZ:removeItem', src, itemData.name, itemData.amount)
            end
        end
    end
end)

RegisterNetEvent('jungleRZ:giveMoney')
AddEventHandler('jungleRZ:giveMoney', function(amount, zoneName)
    local src = source
    if amount and zoneName and inZone(src, zoneName) then
        TriggerEvent('jungleRZ:giveMoneyEvent', src, amount)
    end
end)

RegisterNetEvent('jungleRZ:playerDied')
AddEventHandler('jungleRZ:playerDied', function(killerSrvId, isHS)
    local victim = source
    if killerSrvId and killerSrvId > 0 and killerSrvId ~= victim then
        TriggerClientEvent('jungleRZ:killUpdate', killerSrvId, isHS or false)
    end
    TriggerEvent('jungleRZ:onPlayerDeathServer', victim)
end)
