local playerData = {}
local playersInZone = {}

local rewardSystem = require('server.rewards')

local function initializePlayer(src)
    if not playerData[src] then
        playerData[src] = {
            currentZone = nil,
            position = nil,
            stats = {},
            lastPositionUpdate = GetGameTimer()
        }
    end
end

local function cleanupPlayer(src)
    if playerData[src] then
        if playerData[src].currentZone then
            handleZoneExit(src)
        end
        playerData[src] = nil
        playersInZone[src] = nil
    end
end

local function deleteZoneVehicles(zone)
    if not Config.DeleteVehiclesInZone then return end
    
    local vehicles = GetAllVehicles()
    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        if #(vehCoords - vector3(zone.coords.x, zone.coords.y, zone.coords.z)) <= zone.coords.w then
            DeleteEntity(vehicle)
        end
    end
end

local function isPlayerInZone(src)
    return playersInZone[src] ~= nil
end

local function getZoneByName(zoneName)
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName then
            return zone
        end
    end
    return nil
end

local function handleZoneEntry(src, zone)
    local player = playerData[src]
    player.currentZone = zone.name
    playersInZone[src] = zone.name
    
    if not player.stats[zone.name] then
        player.stats[zone.name] = {
            kills = 0,
            headshots = 0,
            currentReward = 0
        }
    end
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 1)
    end
    
    deleteZoneVehicles(zone)
    
    rewardSystem.giveStartingRewards(src, zone)
    
    TriggerClientEvent("jungleRZ:enterZone", src, zone.name, player.stats[zone.name], 0)
    TriggerEvent("jungleRZ:framework:giveItems", src, zone)
end

local function handleZoneExit(src)
    local player = playerData[src]
    if not player or not player.currentZone then return end
    
    local zoneName = player.currentZone
    playersInZone[src] = nil
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0)
    end
    
    local zone = getZoneByName(zoneName)
    if zone then
        TriggerEvent("jungleRZ:framework:removeItems", src, zone)
    end
    
    player.currentZone = nil
    player.stats[zoneName] = nil
    
    TriggerClientEvent("jungleRZ:exitZone", src)
end

-- Position update handler
RegisterNetEvent("jungleRZ:updatePosition", function(coords)
    local src = source
    initializePlayer(src)
    
    local player = playerData[src]
    local currentTime = GetGameTimer()
    
    -- Anti-teleport check
    if player.position then
        local distance = #(coords - player.position)
        local timeDiff = (currentTime - player.lastPositionUpdate) / 1000
        local maxSpeed = 100 -- meters per second
        
        if distance > (maxSpeed * timeDiff) then
            return
        end
    end
    
    player.position = coords
    player.lastPositionUpdate = currentTime
    
    local zone = API.GetPlayerZone(coords)
    
    if zone and player.currentZone ~= zone.name then
        handleZoneEntry(src, zone)
    elseif not zone and player.currentZone then
        handleZoneExit(src)
    end
end)

RegisterNetEvent("jungleRZ:deleteVehicle", function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and GetEntityType(vehicle) == 2 then
        DeleteEntity(vehicle)
    end
end)

-- Handle player death with killer info
RegisterNetEvent("jungleRZ:playerDied", function(zoneName, killerServerId)
    local src = source
    local player = playerData[src]
    
    if not player or not player.currentZone or player.currentZone ~= zoneName then return end
    
    -- Process kill if killer is valid and in zone
    if killerServerId and killerServerId > 0 and isPlayerInZone(killerServerId) then
        local killer = playerData[killerServerId]
        if killer and killer.currentZone == player.currentZone then
            processKill(killerServerId, src, false) -- ESX doesn't provide headshot info directly
        end
    end
    
    -- Handle respawn
    local zone = getZoneByName(player.currentZone)
    if not zone then return end
    
    local exitPos = nil
    if type(zone.reviveCoords) == "table" and #zone.reviveCoords > 0 then
        exitPos = zone.reviveCoords[math.random(#zone.reviveCoords)]
    else
        exitPos = zone.reviveCoords
    end
    
    if not exitPos then return end
    
    handleZoneExit(src)
    
    Wait(100)
    TriggerClientEvent("jungleRZ:revivePlayer", src, exitPos, exitPos.w or 0.0)
    TriggerEvent("jungleRZ:framework:revivePlayer", src)
end)

function processKill(attackerSrc, victimSrc, isHeadshot)
    local attacker = playerData[attackerSrc]
    if not attacker or not attacker.currentZone then return end
    
    local stats = attacker.stats[attacker.currentZone]
    stats.kills = stats.kills + 1
    
    if isHeadshot then
        stats.headshots = stats.headshots + 1
    end
    
    local zone = rewardSystem.getZoneConfig(attacker.currentZone)
    if not zone then return end
    
    local killReward = rewardSystem.giveKillRewards(attackerSrc, zone, stats)
    
    local headshotBonus = 0
    if isHeadshot then
        headshotBonus = rewardSystem.giveHeadshotRewards(attackerSrc, zone)
    end
    
    local totalReward = killReward + headshotBonus
    TriggerClientEvent("jungleRZ:updateStats", attackerSrc, stats.kills, stats.headshots, totalReward)
end

-- Alternative kill detection using game events (fallback)
AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName ~= 'CEventNetworkEntityDamage' then return end
    
    local victim = data[1]
    local attacker = data[2]
    local isDead = data[6] == 1
    
    if not isDead or not NetworkGetEntityOwner(victim) then return end
    
    local victimSrc = NetworkGetEntityOwner(victim)
    local attackerSrc = NetworkGetEntityOwner(attacker)
    
    if not victimSrc or not attackerSrc or victimSrc == attackerSrc then return end
    
    if not isPlayerInZone(attackerSrc) or not isPlayerInZone(victimSrc) then return end
    
    if Config.BlockCrossZoneDamage and playersInZone[victimSrc] ~= playersInZone[attackerSrc] then
        return
    end
    
    local isHeadshot = data[10] == 31086
    processKill(attackerSrc, victimSrc, isHeadshot)
end)

AddEventHandler('playerDropped', function()
    local src = source
    cleanupPlayer(src)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for src, _ in pairs(playerData) do
        if playerData[src] and playerData[src].currentZone then
            handleZoneExit(src)
        end
    end
end)
