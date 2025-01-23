RegisterNetEvent('jungleRZ:onPlayerDeathServer')
AddEventHandler('jungleRZ:onPlayerDeathServer', function(victim)
    local ped = GetPlayerPed(victim)
    if not ped or ped == 0 then return end
    local coords = GetEntityCoords(ped)
    for _, z in ipairs(Config.Zones) do
        if #(coords - z.coords) <= z.radius then
            if type(z.spawnCoords) == "table" and #z.spawnCoords > 1 then
                local chosenSpawn = z.spawnCoords[math.random(#z.spawnCoords)]
                TriggerClientEvent('jungleRZ:teleportDead', victim, chosenSpawn)
            else
                TriggerClientEvent('jungleRZ:teleportDead', victim, z.spawnCoords)
            end
            TriggerClientEvent('esx_ambulancejob:revive', victim) -- replace to your revive export if needed
            return
        end
    end
end)
