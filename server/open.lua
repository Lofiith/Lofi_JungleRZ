RegisterNetEvent('jungleRZ:onPlayerDeathServer')
AddEventHandler('jungleRZ:onPlayerDeathServer', function(victim)
    local ped = GetPlayerPed(victim)
    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)
    for _, z in ipairs(Config.Zones) do
        if #(coords - z.coords) <= z.radius then
            Wait(1500)
            TriggerClientEvent('jungleRZ:teleportDead', victim, z.spawnCoords)
            Wait(1)
            TriggerClientEvent('esx_ambulancejob:revive', victim) -- replace your revive export if needed
            return
        end
    end
end)
