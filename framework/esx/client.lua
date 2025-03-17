if Config.Framework ~= "esx" then return end

local currentESXZone = nil

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inZone = false

        for _, zone in ipairs(Config.Zones) do
            local center = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
            if #(coords - center) < zone.coords.w then
                if currentESXZone ~= zone.name then
                    currentESXZone = zone.name
                    TriggerServerEvent('jungleRZ:esx:enterZone', zone.name)
                end
                inZone = true
                break
            end
        end

        if not inZone and currentESXZone then
            TriggerServerEvent('jungleRZ:esx:exitZone', currentESXZone)
            currentESXZone = nil
        end

        Wait(500)
    end
end)
