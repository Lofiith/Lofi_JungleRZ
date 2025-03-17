-----------------------------------------------------
---- For more scripts and updates, visit ------------
--------- https://discord.gg/lofidev ----------------
-----------------------------------------------------

Config = {}

-- Framework
Config.Framework = "esx" -- Set which framework to use: "esx", "qbcore", or "ox"
Config.EnableOxInventoryIntegration = true -- Enable if you want to disable inventory / Disable if you want to allow inventory
Config.DeleteVehiclesInZone = false -- Set to true if you want to delete vehicles in the zone
Config.UIPosition = "center-right" -- "bottom-left", "bottom-right", "top-left", "top-right", "center-left", "center-right", "center-top"

-- Blip
Config.EnableBlip = true -- Enable/Disable blip on the map
Config.ZoneBlipIcon = 1 -- Blip icon
Config.ZoneBlipIconColor = 2 -- Icon color (GTA V color code)
Config.ZoneBlipIconScale = 0.8 -- Blip scale (size)

-- Marker
Config.MarkerColor = { r = 255, g = 0, b = 0, a = 100 } -- Optional: Set the color of the marker
Config.MarkerDrawDistance = 50.0 -- Optional: Set the distance to draw the marker

-- Zones configuration
Config.Zones = {
    {
        name = "JungleRZ", -- name of the zone
        coords = vector4(410.5369, -1513.8037, 29.2915, 60), -- x, y, z, radius
        exitCoords = {
            vector3(431.3346, -1451.1184, 29.3419), -- revive points
            vector3(431.3346, -1451.1184, 29.3419) 
        },
        items = {
            { type = "weapon", name = "weapon_pistol", ammo = 100 }
        },
        startingReward = 500, -- first kill reward
        rewardIncrement = 500 -- reward increment per kill
    },
    -- Add more zones as needed...
}
