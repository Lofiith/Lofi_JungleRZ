if Config.Framework ~= "ox" then return end

RegisterNetEvent("jungleRZ:ox:handleInventory", function(zoneName, entering)
    if not Config.EnableOxInventoryIntegration then return end
    
    if entering then
        exports.ox_inventory:weaponWheel(false)
        SetTimeout(100, function()
            exports.ox_inventory:weaponWheel(true)
            if LocalPlayer.state then
                LocalPlayer.state.invHotkeys = false
                LocalPlayer.state.invBusy = true
            end
            
            local weaponName = nil
            for _, zone in ipairs(Config.Zones) do
                if zone.name == zoneName and zone.items then
                    for _, item in ipairs(zone.items) do
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
    else
        exports.ox_inventory:weaponWheel(false)
        if LocalPlayer.state then
            LocalPlayer.state.invHotkeys = true
            LocalPlayer.state.invBusy = false
        end
    end
end)
