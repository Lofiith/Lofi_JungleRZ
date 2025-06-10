API = {}

function API.GetPlayerZone(coords)
    for _, zone in ipairs(Config.Zones) do
        local distance = #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
        if distance <= zone.coords.w then
            return zone
        end
    end
    return nil
end

function API.DrawZoneMarker(zone, distance)
    if not Config.EnableMarkers then return false end
    
    if distance < Config.MarkerDrawDistance then
        DrawMarker(
            1, 
            zone.coords.x,
            zone.coords.y,
            zone.coords.z - 1.0,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            zone.coords.w * 2,
            zone.coords.w * 2,
            100.0, 
            Config.MarkerColor.r,
            Config.MarkerColor.g,
            Config.MarkerColor.b,
            Config.MarkerColor.a,
            false,
            true,
            2,
            false,
            nil,
            nil,
            false
        )
        return true
    end
    return false
end


function API.CreateBlip(coords, name, sprite, scale, color, shortRange)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, shortRange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

function API.CreateRadiusBlip(coords, radius, color, alpha)
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, radius)
    SetBlipColour(blip, color)
    SetBlipAlpha(blip, alpha)
    return blip
end
