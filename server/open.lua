RegisterNetEvent('jungleRZ:onPlayerDeathServer')
AddEventHandler('jungleRZ:onPlayerDeathServer', function()
    local src = source
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local coords = GetEntityCoords(ped)
    for _, z in ipairs(Config.Zones) do
        if #(coords - z.coords) <= z.radius then
            if type(z.spawnCoords) == "table" and #z.spawnCoords > 1 then
                local chosenSpawn = z.spawnCoords[math.random(#z.spawnCoords)]
                TriggerClientEvent('jungleRZ:teleportDead', src, chosenSpawn)
            else
                TriggerClientEvent('jungleRZ:teleportDead', src, z.spawnCoords)
            end
            TriggerClientEvent('esx_ambulancejob:revive', src) -- Replace with your revive export if needed
            return
        end
    end
end)
