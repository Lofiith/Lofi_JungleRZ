RegisterNetEvent('jungleRZ:onPlayerDeathServer')
AddEventHandler('jungleRZ:onPlayerDeathServer', function(victim)
    local src = victim
    local pdata = PlayerZoneData[src]
    if pdata then
         local zone = pdata.zone
         if type(zone.spawnCoords) == "table" and #zone.spawnCoords > 1 then
             local chosenSpawn = zone.spawnCoords[math.random(#zone.spawnCoords)]
             TriggerClientEvent('jungleRZ:teleportDead', src, chosenSpawn)
         else
             TriggerClientEvent('jungleRZ:teleportDead', src, zone.spawnCoords)
         end
         if not Config.UseInternalRevive then
            Wait(1000)
             TriggerClientEvent(Config.ReviveEvent, src)
         end
         PlayerZoneData[src] = nil
    end
end)
