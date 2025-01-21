if Config.Framework ~= 'qbcore' then return end

local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('jungleRZ:giveItem')
AddEventHandler('jungleRZ:giveItem', function(src, itemName, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddItem(itemName, amount or 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add')
    end
end)

RegisterNetEvent('jungleRZ:removeItem')
AddEventHandler('jungleRZ:removeItem', function(src, itemName, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.RemoveItem(itemName, amount or 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
    end
end)

RegisterNetEvent('jungleRZ:giveMoneyEvent')
AddEventHandler('jungleRZ:giveMoneyEvent', function(src, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddMoney('cash', amount)
    end
end)
