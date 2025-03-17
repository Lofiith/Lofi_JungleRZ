if Config.Framework ~= "ox" then return end

RegisterNetEvent('jungleRZ:ox:enterZone', function(zoneName)
    local src = source
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName and z.items then
            for _, item in ipairs(z.items) do
                if item.type == "weapon" then
                    exports.ox_inventory:AddItem(src, item.name, 1, { ammo = item.ammo or 100 })
                else
                    exports.ox_inventory:AddItem(src, item.name, 1)
                end
            end
            break
        end
    end
end)

RegisterNetEvent('jungleRZ:ox:exitZone', function(zoneName)
    local src = source
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName and z.items then
            for _, item in ipairs(z.items) do
                exports.ox_inventory:RemoveItem(src, item.name, 1)
            end
            break
        end
    end
end)
