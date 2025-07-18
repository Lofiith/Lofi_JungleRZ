if Config.Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Handle giving items to player
AddEventHandler("jungleRZ:framework:giveItems", function(src, zone)
    if not zone.items then return end
    
    if Config.UseOxInventory then
        for _, item in ipairs(zone.items) do
            local count = exports.ox_inventory:GetItem(src, item.name, nil, true)
            if count == 0 then
                if item.type == "weapon" then
                    exports.ox_inventory:AddItem(src, item.name, 1)
                    Wait(100)
                    TriggerClientEvent("jungleRZ:equipWeapon", src, GetHashKey(item.name))
                else
                    exports.ox_inventory:AddItem(src, item.name, 1)
                end
            end
        end
    elseif Config.Framework == "esx" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        
        for _, item in ipairs(zone.items) do
            if item.type == "weapon" then
                if not xPlayer.hasWeapon(item.name) then
                    xPlayer.addWeapon(item.name, item.ammo or 100)
                end
            else
                local currentCount = xPlayer.getInventoryItem(item.name).count
                if currentCount == 0 then
                    xPlayer.addInventoryItem(item.name, 1)
                end
            end
        end
    elseif Config.Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end
        
        for _, item in ipairs(zone.items) do
            local hasItem = Player.Functions.GetItemByName(item.name)
            if not hasItem then
                if item.type == "weapon" then
                    Player.Functions.AddItem(item.name, 1, false, {ammo = item.ammo or 100})
                    TriggerClientEvent('weapons:client:SetCurrentWeapon', src, item.name, false)
                else
                    Player.Functions.AddItem(item.name, 1)
                    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[item.name], "add")
                end
            end
        end
    end
end)

-- Handle removing items from player
AddEventHandler("jungleRZ:framework:removeItems", function(src, zone)
    if not zone.items then return end
    TriggerClientEvent("jungleRZ:removeWeapons", src)
    Wait(100)
    
    if Config.UseOxInventory then
        for _, item in ipairs(zone.items) do
            exports.ox_inventory:RemoveItem(src, item.name, 1)
        end
    elseif Config.Framework == "esx" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        
        for _, item in ipairs(zone.items) do
            if item.type == "weapon" then
                xPlayer.removeWeapon(item.name)
            else
                xPlayer.removeInventoryItem(item.name, 1)
            end
        end
    elseif Config.Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end
        
        for _, item in ipairs(zone.items) do
            Player.Functions.RemoveItem(item.name, 1)
            if item.type ~= "weapon" then
                TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[item.name], "remove")
            end
        end
    end
end)

-- Handle giving money to player
AddEventHandler("jungleRZ:framework:giveMoney", function(src, amount)
    if Config.UseOxInventory then
        exports.ox_inventory:AddItem(src, 'money', amount)
    elseif Config.Framework == "esx" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addMoney(amount)
        end
    elseif Config.Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney("cash", amount, "redzone-kill")
        end
    end
end)

AddEventHandler("jungleRZ:framework:giveItem", function(src, itemName, count)
    if Config.UseOxInventory then
        exports.ox_inventory:AddItem(src, itemName, count)
    elseif Config.Framework == "esx" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addInventoryItem(itemName, count)
        end
    elseif Config.Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem(itemName, count)
            TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[itemName], "add")
        end
    end
end)

AddEventHandler("jungleRZ:framework:giveWeapon", function(src, weaponName, ammo)
    if Config.UseOxInventory then
        exports.ox_inventory:AddItem(src, weaponName, 1)
        if ammo > 0 then
            local ammoType = exports.ox_inventory:GetItemData(weaponName).ammo
            if ammoType then
                exports.ox_inventory:AddItem(src, ammoType, ammo)
            end
        end
    elseif Config.Framework == "esx" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addWeapon(weaponName, ammo)
        end
    elseif Config.Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem(weaponName, 1, false, {serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))})
            TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[weaponName], "add")
            if ammo > 0 then
                local ammoType = QBCore.Shared.Weapons[weaponName].ammotype
                if ammoType then
                    Player.Functions.AddItem(ammoType, ammo)
                end
            end
        end
    end
end)

-- Handle reviving player
AddEventHandler("jungleRZ:framework:revivePlayer", function(src)
    if Config.Framework == "esx" then
        TriggerClientEvent('esx_ambulancejob:revive', src)
    elseif Config.Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.SetMetaData("isdead", false)
            Player.Functions.SetMetaData("inlaststand", false)
            TriggerClientEvent('hospital:client:Revive', src)
        end
    end
    
    if Config.UseOxInventory then
        TriggerClientEvent('ox_inventory:disarm', src)
    end
end)
