RegisterNetEvent('jungleRZ:OnEnterZone', function(zone)
    DisplayRadar(false)
    -- implement your hud logic if you want to hide the hud
end)

RegisterNetEvent('jungleRZ:OnExitZone', function(zone)
    DisplayRadar(true)
    -- implement your hud logic if you want to show the hud
end)

RegisterNetEvent('jungleRZ:teleportDead')
AddEventHandler('jungleRZ:teleportDead', function(spawnCoords)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityHeading(ped, spawnCoords.w)
end)
