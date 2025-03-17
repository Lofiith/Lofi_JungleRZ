if Config.Framework ~= "esx" then return end

ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('jungleRZ:esx:enterZone', function(zoneName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName and z.items then
            for _, item in ipairs(z.items) do
                if item.type == "weapon" then
                    xPlayer.addWeapon(item.name, item.ammo or 100)
                else
                    xPlayer.addInventoryItem(item.name, 1)
                end
            end
            break
        end
    end
end)

RegisterNetEvent('jungleRZ:esx:exitZone', function(zoneName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName and z.items then
            for _, item in ipairs(z.items) do
                if item.type == "weapon" then
                    xPlayer.removeWeapon(item.name)
                else
                    xPlayer.removeInventoryItem(item.name, 1)
                end
            end
            break
        end
    end
end)
