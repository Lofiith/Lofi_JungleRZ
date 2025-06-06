if Config.Framework ~= "qbcore" then return end

local QBCore = exports['qb-core']:GetCoreObject()

function QBHandleZoneEntry(src, zoneName)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName and zone.items then
            for _, item in ipairs(zone.items) do
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
end

function QBHandleZoneExit(src, zoneName)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName and zone.items then
            for _, item in ipairs(zone.items) do
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
end

function QBGiveReward(src, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddMoney("cash", amount, "redzone-kill")
    end
end
