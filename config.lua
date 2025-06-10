Config = {}

-- Framework
Config.Framework = "esx" -- "esx" or "qbcore"
Config.UseOxInventory = true -- Use ox_inventory for item management
Config.AllowInventoryAccess = false -- Allow players to open inventory in zone (If false, weapon wheel will be used)

-- Zone Settings
Config.DeleteVehiclesInZone = true -- Delete all vehicles when entering zone
Config.UseRoutingBuckets = false -- Separate players in different buckets
Config.BlockCrossZoneDamage = false -- Only register kills within same zone

-- UI Settings
Config.UIPosition = "center-right"

-- Visual Settings
Config.EnableBlip = true -- Enable zone blip on map
Config.EnableMarkers = true -- Enable zone markers
Config.ZoneBlipIcon = 310 -- Blip icon ID
Config.ZoneBlipIconColor = 1 -- Blip color ID
Config.ZoneBlipIconScale = 0.8 -- Blip scale

Config.MarkerColor = { r = 255, g = 0, b = 0, a = 100 } -- Zone Color
Config.MarkerDrawDistance = 60.0 -- Distance to draw markers (Increase in distances can cause performance issues)

-- Zones
Config.Zones = {
    {
        name = "JungleRZ", -- zone name
        coords = vector4(410.5369, -1513.8037, 29.2915, 40), -- zone center coordinates (x, y, z, RADIUS)
        reviveCoords = { -- coordinates to revive players
            vector4(425.2147, -1448.5138, 29.3411, 0.0),
            vector4(431.3346, -1451.1184, 29.3419, 0.0)
        },
        items = {
            { type = "weapon", name = "WEAPON_PISTOL", ammo = 100 } -- Example weapon item
        },
        startingReward = 500, -- Starting reward for entering the zone
        rewardIncrement = 500 -- Incremental reward for each kill
    }
}
