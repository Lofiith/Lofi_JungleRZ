local isDead = false

if Config.Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
    
    AddEventHandler('esx:onPlayerDeath', function(data)
        isDead = true
        if currentZone then
            -- Send killer info if available
            local killerServerId = data.killerServerId or 0
            TriggerServerEvent("jungleRZ:playerDied", currentZone, killerServerId)
        end
    end)
    
    AddEventHandler('playerSpawned', function(spawn)
        isDead = false
    end)
    
elseif Config.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
    
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        isDead = false
    end)
    
    AddEventHandler('QBCore:Client:OnPlayerDeath', function()
        isDead = true
        if currentZone then
            TriggerServerEvent("jungleRZ:playerDied", currentZone, 0)
        end
    end)
    
    AddEventHandler('hospital:client:RespawnAtHospital', function()
        isDead = false
    end)
end

-- Export function to check if player is dead
function IsPlayerDead()
    return isDead
end
