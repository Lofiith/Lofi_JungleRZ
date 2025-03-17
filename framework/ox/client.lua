if Config.Framework ~= "ox" then return end

local inOxZone = false
local currentOxZone = nil

local function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, veh = FindFirstVehicle()
        if not veh or veh == 0 then
            EndFindVehicle(handle)
            return
        end
        local finished = false
        repeat
            coroutine.yield(veh)
            finished, veh = FindNextVehicle(handle)
        until not finished
        EndFindVehicle(handle)
    end)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local isInZone = false
        local zoneName = nil

        for _, zone in ipairs(Config.Zones) do
            if #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z)) < zone.coords.w then
                isInZone = true
                zoneName = zone.name
                break
            end
        end

        if isInZone and not inOxZone then
            inOxZone = true
            currentOxZone = zoneName
            TriggerServerEvent('jungleRZ:ox:enterZone', zoneName)
            if Config.EnableOxInventoryIntegration then
                exports.ox_inventory:weaponWheel(false)
                SetTimeout(100, function()
                    exports.ox_inventory:weaponWheel(true)
                    if LocalPlayer.state then
                        LocalPlayer.state.invHotkeys = false
                        LocalPlayer.state.invBusy = true
                    end
                    local weaponName = nil
                    for _, z in ipairs(Config.Zones) do
                        if z.name == zoneName and z.items then
                            for _, item in ipairs(z.items) do
                                if item.type == "weapon" then
                                    weaponName = item.name
                                    break
                                end
                            end
                        end
                    end
                    if weaponName then
                        SetTimeout(300, function()
                            if LocalPlayer.state then
                                LocalPlayer.state.invBusy = false
                                LocalPlayer.state.canUseWeapons = true
                            end
                            local slotId = exports.ox_inventory:GetSlotIdWithItem(weaponName, nil, true)
                            if slotId then
                                exports.ox_inventory:useSlot(slotId)
                                SetTimeout(150, function()
                                    local weaponHash = GetHashKey(weaponName)
                                    RemoveWeaponFromPed(PlayerPedId(), weaponHash)
                                    GiveWeaponToPed(PlayerPedId(), weaponHash, 100, false, true)
                                    SetCurrentPedWeapon(PlayerPedId(), weaponHash, true)
                                    if LocalPlayer.state then
                                        LocalPlayer.state.invBusy = true
                                    end
                                end)
                            else
                                if LocalPlayer.state then
                                    LocalPlayer.state.invBusy = true
                                end
                            end
                        end)
                    else
                        if LocalPlayer.state then
                            LocalPlayer.state.invBusy = true
                        end
                    end
                end)
            end
        elseif not isInZone and inOxZone then
            TriggerServerEvent('jungleRZ:ox:exitZone', currentOxZone)
            inOxZone = false
            currentOxZone = nil
            if Config.EnableOxInventoryIntegration then
                exports.ox_inventory:weaponWheel(false)
                if LocalPlayer.state then
                    LocalPlayer.state.invHotkeys = true
                    LocalPlayer.state.invBusy = false
                end
            end
        end

        Wait(500)
    end
end)

CreateThread(function()
    while true do
        if Config.DeleteVehiclesInZone then
            for _, zone in ipairs(Config.Zones) do
                local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
                for veh in EnumerateVehicles() do
                    if #(GetEntityCoords(veh) - center) < zone.coords.w then
                        DeleteEntity(veh)
                    end
                end
            end
        end
        Wait(1000)
    end
end)
