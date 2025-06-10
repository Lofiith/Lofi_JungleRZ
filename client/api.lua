local api = {}

function api.AddBlip(coords, sprite, scale, color, name, shortRange)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, shortRange or true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

function api.AddRadiusBlip(coords, radius, color, alpha)
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, radius)
    SetBlipColour(blip, color)
    SetBlipAlpha(blip, alpha)
    return blip
end

function api.DrawMarker(coords, radius, color)
    DrawMarker(
        28,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        radius, radius, radius,
        color.r, color.g, color.b, color.a,
        false, true, 2, false, nil, nil, false
    )
end

return api
