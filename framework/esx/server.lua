if Config.Framework ~= 'esx' then return end

ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('jungleRZ:giveItem')
AddEventHandler('jungleRZ:giveItem', function(itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.addInventoryItem(itemName, amount or 1)
    end
end)

RegisterNetEvent('jungleRZ:removeItem')
AddEventHandler('jungleRZ:removeItem', function(itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.removeInventoryItem(itemName, amount or 1)
    end
end)

RegisterNetEvent('jungleRZ:giveMoneyEvent')
AddEventHandler('jungleRZ:giveMoneyEvent', function(amt)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.addMoney(amt)
    end
end)
