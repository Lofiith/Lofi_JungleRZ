if Config.Framework ~= "esx" then return end

local ESX = exports["es_extended"]:getSharedObject()

function ESXHandleZoneEntry(src, zoneName)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName and zone.items then
            for _, item in ipairs(zone.items) do
                if item.type == "weapon" then
                    xPlayer.addWeapon(item.name, item.ammo or 100)
                else
                    xPlayer.addInventoryItem(item.name, 1)
                end
            end
            break
        end
    end
end

function ESXHandleZoneExit(src, zoneName)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName and zone.items then
            for _, item in ipairs(zone.items) do
                if item.type == "weapon" then
                    xPlayer.removeWeapon(item.name)
                else
                    xPlayer.removeInventoryItem(item.name, 1)
                end
            end
            break
        end
    end
end

function ESXGiveReward(src, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.addMoney(amount)
    end
end
