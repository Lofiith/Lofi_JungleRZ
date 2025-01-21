if Config.Framework ~= 'esx' then return end

ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('jungleRZ:giveItem')
AddEventHandler('jungleRZ:giveItem', function(src, itemName, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.addInventoryItem(itemName, amount or 1)
    end
end)

RegisterNetEvent('jungleRZ:removeItem')
AddEventHandler('jungleRZ:removeItem', function(src, itemName, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.removeInventoryItem(itemName, amount or 1)
    end
end)

RegisterNetEvent('jungleRZ:giveMoneyEvent')
AddEventHandler('jungleRZ:giveMoneyEvent', function(src, amt)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.addMoney(amt)
    end
end)
