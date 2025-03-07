-- Natives (performance)
local PlayerPedId <const>                  = PlayerPedId
local GetEntityCoords <const>              = GetEntityCoords
local Wait <const>                         = Wait
local CreateThread <const>                 = CreateThread
local TriggerServerEvent <const>           = TriggerServerEvent
local DoesEntityExist <const>              = DoesEntityExist
local IsEntityDead <const>                 = IsEntityDead
local IsPedAPlayer <const>                 = IsPedAPlayer
local NetworkGetPlayerIndexFromPed <const> = NetworkGetPlayerIndexFromPed
local GetPlayerServerId <const>            = GetPlayerServerId
local IsPedDeadOrDying <const>             = IsPedDeadOrDying
local AddEventHandler <const>              = AddEventHandler
local RegisterNetEvent <const>             = RegisterNetEvent
local DrawMarker <const>                   = DrawMarker
local DeleteEntity <const>                 = DeleteEntity
local IsPedInAnyVehicle <const>            = IsPedInAnyVehicle
local string_sub <const>                   = string.sub
local GetHashKey <const>                   = GetHashKey
local GiveWeaponToPed <const>              = GiveWeaponToPed
local RemoveWeaponFromPed <const>          = RemoveWeaponFromPed
local SetPedAmmo <const>                   = SetPedAmmo
local SetCurrentPedWeapon <const>          = SetCurrentPedWeapon
local vector3 <const>                      = vector3
local GetPedLastDamageBone <const>         = GetPedLastDamageBone
local AddBlipForCoord <const>              = AddBlipForCoord
local SetBlipSprite <const>                = SetBlipSprite
local SetBlipDisplay <const>               = SetBlipDisplay
local SetBlipScale <const>                 = SetBlipScale
local SetBlipColour <const>                = SetBlipColour
local SetBlipAsShortRange <const>          = SetBlipAsShortRange
local BeginTextCommandSetBlipName <const>  = BeginTextCommandSetBlipName
local AddTextComponentString <const>       = AddTextComponentString
local EndTextCommandSetBlipName <const>    = EndTextCommandSetBlipName
local AddBlipForRadius <const>             = AddBlipForRadius
local SendNUIMessage <const>               = SendNUIMessage

local inZone, currentZone = false, nil
local domeThread = nil
local HEAD_BONE <const> = 31086

local function wasHeadshot(victimPed)
    local success, bone = GetPedLastDamageBone(victimPed)
    return (success and bone == HEAD_BONE)
end

local function isInsideZone(z, coords)
    return #(coords - z.coords) <= z.radius
end

local function resetStats()
    SendNUIMessage({ action = 'resetUI', kills = 0, headshots = 0, reward = (currentZone and currentZone.rewardStart or 0) })
end

local function drawDomeForZone(z)
    while inZone and currentZone == z do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        if isInsideZone(z, coords) then
            DrawMarker(
                28, z.coords.x, z.coords.y, z.coords.z,
                0, 0, 0, 0, 0, 0,
                z.radius, z.radius, z.radius,
                Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a,
                false, false, 2, false, nil, nil, false
            )
            if IsPedInAnyVehicle(ped, false) then
                DeleteEntity(GetVehiclePedIsIn(ped, false))
            end
        end
        Wait(0)
    end
end

local function AddCustomWeaponLabel(itemName)
    if string.sub(itemName:lower(), 1, 7) == "weapon_" then
        local upper = string.upper(itemName)
        local label = "Custom " .. itemName
        AddTextEntry(upper, label)
    end
end

local function GiveWeapon(itemName)
    if Config.Using_ox_inventory then
        exports.ox_inventory:weaponWheel(true)
    end
    if string.sub(itemName:lower(), 1, 7) == "weapon_" then
        local weaponHash = GetHashKey(itemName)
        GiveWeaponToPed(PlayerPedId(), weaponHash, 500, false, true)
        SetCurrentPedWeapon(PlayerPedId(), weaponHash, true)
        Wait(2500)
        GiveWeaponToPed(PlayerPedId(), weaponHash, 500, false, true)
        SetCurrentPedWeapon(PlayerPedId(), weaponHash, true)
    end
end

local function RemoveWeapon(itemName)
    if Config.Using_ox_inventory then
        exports.ox_inventory:weaponWheel(false)
    end
    if string.sub(itemName:lower(), 1, 7) == "weapon_" then
        local weaponHash = GetHashKey(itemName)
        RemoveWeaponFromPed(PlayerPedId(), weaponHash)
    end
end

local function enterZone(z)
    inZone, currentZone = true, z
    LocalPlayer.state.invBusy = true
    LocalPlayer.state.invHotkeys = false
    TriggerServerEvent('jungleRZ:enterZone')
    Wait(100)
    SendNUIMessage({ action = 'resetUI', kills = 0, headshots = 0, reward = z.rewardStart or 0 })
    SendNUIMessage({ action = 'showUI' })
    TriggerEvent('jungleRZ:OnEnterZone', z)
    for _, itemData in ipairs(z.items) do
        AddCustomWeaponLabel(itemData.name)
        GiveWeapon(itemData.name)
    end
    if not domeThread then
        domeThread = CreateThread(function()
            drawDomeForZone(z)
            domeThread = nil
        end)
    end
end

local function exitZone(z)
    inZone = false
    LocalPlayer.state.invBusy = false
    LocalPlayer.state.invHotkeys = true
    TriggerServerEvent('jungleRZ:exitZone')
    SendNUIMessage({ action = 'hideUI' })
    resetStats()
    TriggerEvent('jungleRZ:OnExitZone', z)
    for _, itemData in ipairs(z.items) do
        RemoveWeapon(itemData.name)
    end
end

local function createBlips()
    for _, z in ipairs(Config.Zones) do
        local blip = AddBlipForCoord(z.coords)
        SetBlipSprite(blip, Config.BlipSprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.BlipScale)
        SetBlipColour(blip, Config.BlipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(z.name or "RedZone")
        EndTextCommandSetBlipName(blip)
        local rBlip = AddBlipForRadius(z.coords, z.radius)
        SetBlipColour(rBlip, Config.BlipColor)
        SetBlipAlpha(rBlip, 128)
    end
end

CreateThread(function()
    createBlips()
    while true do
        local pedCoords = GetEntityCoords(PlayerPedId())
        local inside, zFound = false, nil
        for _, z in ipairs(Config.Zones) do
            if isInsideZone(z, pedCoords) then
                inside, zFound = true, z
                break
            end
        end
        if not inZone and inside then
            enterZone(zFound)
        elseif inZone and not inside and currentZone then
            exitZone(currentZone)
        end
        Wait(500)
    end
end)

AddEventHandler("gameEventTriggered", function(evt, data)
    if evt == "CEventNetworkEntityDamage" then
        local victim = data[1]
        local attacker = data[2]
        if NetworkGetPlayerIndexFromPed(victim) == PlayerId() and IsEntityDead(victim) then
            local atkId, isHS = -1, wasHeadshot(victim)
            if DoesEntityExist(attacker) and attacker ~= victim then
                if IsPedAPlayer(attacker) then
                    local atkClient = NetworkGetPlayerIndexFromPed(attacker)
                    if atkClient and atkClient >= 0 then
                        atkId = GetPlayerServerId(atkClient)
                    end
                end
            end
            TriggerServerEvent('jungleRZ:playerDied', atkId, isHS)
        end
    end
end)

RegisterNetEvent('jungleRZ:updateKillUI')
AddEventHandler('jungleRZ:updateKillUI', function(kills, headshots, reward)
    SendNUIMessage({ action = 'updateUI', kills = kills, headshots = headshots, reward = reward })
end)

CreateThread(function()
    Wait(500)
    SendNUIMessage({ action = 'setUIPosition', position = Config.UIPosition })
end)
