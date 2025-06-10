currentZone = nil
local cache = {}
local originalWeaponWheelState = nil
local isUIVisible = false

local function sendUIMessage(data)
    SendNUIMessage(data)
end

local function updateUI(kills, headshots, reward)
    sendUIMessage({
        action = "updateUI",
        kills = kills,
        headshots = headshots,
        reward = reward
    })
end

RegisterNetEvent("jungleRZ:enterZone", function(zoneName, stats, startingReward)
    currentZone = zoneName
    
    cache.vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if cache.vehicle and cache.vehicle ~= 0 then
        TriggerServerEvent("jungleRZ:deleteVehicle", VehToNet(cache.vehicle))
    end
    
    -- Show UI
    isUIVisible = true
    sendUIMessage({ action = "setUIPosition", position = Config.UIPosition })
    sendUIMessage({ action = "showUI" })
    updateUI(stats.kills, stats.headshots, startingReward or stats.reward)
    
    if Config.UseOxInventory and not Config.AllowInventoryAccess then
        originalWeaponWheelState = LocalPlayer.state.invHotkeys
        exports.ox_inventory:weaponWheel(true)
        LocalPlayer.state.invHotkeys = false
    end
end)

RegisterNetEvent("jungleRZ:exitZone", function()
    currentZone = nil
    isUIVisible = false
    
    -- Force hide UI
    sendUIMessage({ action = "hideUI" })
    sendUIMessage({ action = "resetUI", kills = 0, headshots = 0, reward = 0 })
    
    if Config.UseOxInventory and not Config.AllowInventoryAccess then
        exports.ox_inventory:weaponWheel(false)
        if originalWeaponWheelState ~= nil then
            LocalPlayer.state.invHotkeys = originalWeaponWheelState
            originalWeaponWheelState = nil
        end
    end
end)

RegisterNetEvent("jungleRZ:updateStats", function(kills, headshots, reward)
    if isUIVisible then
        updateUI(kills, headshots, reward)
    end
end)

RegisterNetEvent("jungleRZ:equipWeapon", function(weaponHash)
    GiveWeaponToPed(PlayerPedId(), weaponHash, 100, false, true)
    SetPedAmmo(PlayerPedId(), weaponHash, 100)
end)

-- Position update thread
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        TriggerServerEvent("jungleRZ:updatePosition", coords)
        Wait(500)
    end
end)

if Config.EnableMarkers then
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local waitTime = 500
            
            for _, zone in ipairs(Config.Zones) do
                local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
                local distance = #(coords - center)
                
                if API.DrawZoneMarker(zone, distance) then
                    waitTime = 0
                end
            end
            
            Wait(waitTime)
        end
    end)
end

if Config.EnableBlip then
    CreateThread(function()
        for _, zone in ipairs(Config.Zones) do
            API.CreateBlip(zone.coords, zone.name, Config.ZoneBlipIcon, Config.ZoneBlipIconScale, Config.ZoneBlipIconColor, true)
            API.CreateRadiusBlip(zone.coords, zone.coords.w, 1, 128)
        end
    end)
end

RegisterNetEvent("jungleRZ:removeWeapons", function()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
end)

RegisterNetEvent("jungleRZ:revivePlayer", function(coords, heading)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    SetEntityHeading(ped, heading)
end)

-- Ensure UI is hidden on resource start/restart
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        sendUIMessage({ action = "hideUI" })
        isUIVisible = false
    end
end)
