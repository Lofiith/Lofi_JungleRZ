if Config.Framework ~= "qbcore" then return end

local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('jungleRZ:qb:enterZone', function(zoneName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName and z.items then
            for _, item in ipairs(z.items) do
                if item.type == "weapon" then
                    Player.Functions.AddWeapon(item.name, item.ammo or 100)
                else
                    Player.Functions.AddItem(item.name, 1)
                    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[item.name], "add")
                end
            end
            break
        end
    end
end)

RegisterNetEvent('jungleRZ:qb:exitZone', function(zoneName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName and z.items then
            for _, item in ipairs(z.items) do
                if item.type == "weapon" then
                    Player.Functions.RemoveWeapon(item.name)
                else
                    Player.Functions.RemoveItem(item.name, 1)
                    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[item.name], "remove")
                end
            end
            break
        end
    end
end)
