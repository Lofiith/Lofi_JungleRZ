if Config.Framework ~= "ox" then return end

function OXHandleZoneEntry(src, zoneName)
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName and zone.items then
            for _, item in ipairs(zone.items) do
                if item.type == "weapon" then
                    exports.ox_inventory:AddItem(src, item.name, 1, { ammo = item.ammo or 100 })
                else
                    exports.ox_inventory:AddItem(src, item.name, 1)
                end
            end
            break
        end
    end
    
    if Config.EnableOxInventoryIntegration then
        TriggerClientEvent("jungleRZ:ox:handleInventory", src, zoneName, true)
    end
end

function OXHandleZoneExit(src, zoneName)
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName and zone.items then
            for _, item in ipairs(zone.items) do
                exports.ox_inventory:RemoveItem(src, item.name, 1)
            end
            break
        end
    end
    
    if Config.EnableOxInventoryIntegration then
        TriggerClientEvent("jungleRZ:ox:handleInventory", src, zoneName, false)
    end
end

function OXGiveReward(src, amount)
    exports.ox_inventory:AddItem(src, 'money', amount)
end
