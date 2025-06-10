local isDead = false

if Config.Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
    
    AddEventHandler('esx:onPlayerDeath', function(data)
        isDead = true
        if currentZone then
            TriggerServerEvent("jungleRZ:playerDied")
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
            TriggerServerEvent("jungleRZ:playerDied")
        end
    end)
    
    AddEventHandler('hospital:client:RespawnAtHospital', function()
        isDead = false
    end)
end

-- Export death status
function IsPlayerDead()
    return isDead
end

exports('IsPlayerDead', IsPlayerDead)
