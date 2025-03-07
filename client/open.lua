RegisterNetEvent('jungleRZ:OnEnterZone', function(zone)
    DisplayRadar(false)
end)

RegisterNetEvent('jungleRZ:OnExitZone', function(zone)
    DisplayRadar(true)
end)

RegisterNetEvent('jungleRZ:teleportDead')
AddEventHandler('jungleRZ:teleportDead', function(spawnCoords)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityHeading(ped, spawnCoords.w)
end)
