local playerData = {}
local playersInZone = {}

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
        playerData[src] = nil
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

local function handleZoneEntry(src, zone)
    local player = playerData[src]
    player.currentZone = zone.name
    playersInZone[src] = zone.name
    
    if not player.stats[zone.name] then
        player.stats[zone.name] = {
            kills = 0,
            headshots = 0,
            currentReward = zone.startingReward,
            rewardIncrement = zone.rewardIncrement
        }
    end
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 1)
    end
    
    deleteZoneVehicles(zone)
    
    TriggerClientEvent("jungleRZ:enterZone", src, zone.name, player.stats[zone.name])
    TriggerEvent("jungleRZ:framework:giveItems", src, zone)
end

local function handleZoneExit(src)
    local player = playerData[src]
    if not player or not player.currentZone then return end
    
    local zoneName = player.currentZone -- Store zone name before clearing
    playersInZone[src] = nil
    
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(src, 0)
    end
    
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName then
            TriggerEvent("jungleRZ:framework:removeItems", src, zone)
            break
        end
    end
    
    player.currentZone = nil
    player.stats[zoneName] = nil
    
    TriggerClientEvent("jungleRZ:exitZone", src)
end


RegisterNetEvent("jungleRZ:updatePosition", function(coords)
    local src = source
    initializePlayer(src)
    
    local player = playerData[src]
    local currentTime = GetGameTimer()
    
    -- Basic anti-teleport check
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

RegisterNetEvent("jungleRZ:playerDied", function()
    local src = source
    local player = playerData[src]
    
    if not player or not player.currentZone then return end
    
    local exitPos = nil
    for _, zone in ipairs(Config.Zones) do
        if zone.name == player.currentZone then
            if type(zone.reviveCoords) == "table" and #zone.reviveCoords > 0 then
                exitPos = zone.reviveCoords[math.random(#zone.reviveCoords)]
            else
                exitPos = zone.reviveCoords
            end
            break
        end
    end
    
    if not exitPos then return end
    
    handleZoneExit(src)
    
    Wait(100)
    TriggerClientEvent("jungleRZ:revivePlayer", src, exitPos, exitPos.w or 0.0)
    TriggerEvent("jungleRZ:framework:revivePlayer", src)
end)

AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName ~= 'CEventNetworkEntityDamage' then return end
    
    local victim = data[1]
    local attacker = data[2]
    local isDead = data[6] == 1
    
    if not isDead then return end
    
    -- Check if both are players
    local victimSrc = NetworkGetEntityOwner(victim)
    local attackerSrc = NetworkGetEntityOwner(attacker)
    
    if not victimSrc or not attackerSrc or victimSrc == attackerSrc then return end
    
    -- Check if attacker is in zone
    if not isPlayerInZone(attackerSrc) then return end
    
    -- Check if cross-zone damage is blocked
    if Config.BlockCrossZoneDamage then
        if playersInZone[victimSrc] ~= playersInZone[attackerSrc] then
            return
        end
    end
    
    -- Process the kill
    local player = playerData[attackerSrc]
    if player and player.currentZone then
        local stats = player.stats[player.currentZone]
        stats.kills = stats.kills + 1
        
        -- Check for headshot (bone 31086)
        local isHeadshot = data[10] == 31086
        if isHeadshot then
            stats.headshots = stats.headshots + 1
        end
        
        local reward = stats.currentReward
        TriggerEvent("jungleRZ:framework:giveMoney", attackerSrc, reward)
        
        TriggerClientEvent("jungleRZ:updateStats", attackerSrc, stats.kills, stats.headshots, reward)
        
        stats.currentReward = stats.currentReward + stats.rewardIncrement
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    cleanupPlayer(src)
end)
