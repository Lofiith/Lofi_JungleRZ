if Config.Framework ~= "qbcore" then return end

local currentQBZone = nil

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inZone = false

        for _, zone in ipairs(Config.Zones) do
            local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
            if #(coords - center) < zone.coords.w then
                if currentQBZone ~= zone.name then
                    currentQBZone = zone.name
                    TriggerServerEvent('jungleRZ:qb:enterZone', zone.name)
                end
                inZone = true
                break
            end
        end

        if not inZone and currentQBZone then
            TriggerServerEvent('jungleRZ:qb:exitZone', currentQBZone)
            currentQBZone = nil
        end

        Wait(500)
    end
end)
