RegisterNetEvent('jungleRZ:OnEnterZone', function(zone)
    DisplayRadar(false)
    -- implement your own logic here
end)

RegisterNetEvent('jungleRZ:OnExitZone', function(zone)
    DisplayRadar(true)
    -- implement your own logic here
end)

RegisterNetEvent('jungleRZ:teleportDead')
AddEventHandler('jungleRZ:teleportDead', function(spawnCoords)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityHeading(ped, spawnCoords.w)
    if Config.UseInternalRevive then
        NetworkResurrectLocalPlayer(spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
        ClearPedTasksImmediately(ped)
    end
end)
