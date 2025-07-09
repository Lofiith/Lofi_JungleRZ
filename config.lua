-----------------------------------------------------
---- For more scripts and updates, visit ------------
--------- https://discord.gg/lofidev ----------------
-----------------------------------------------------
Config = {}

-- Framework
Config.Framework = "esx" -- "esx" or "qbcore"
Config.UseOxInventory = true -- Use ox_inventory for item management
Config.AllowInventoryAccess = false -- Allow players to open inventory in zone (If false, weapon wheel will be used)

-- Zone Settings
Config.DeleteVehiclesInZone = true -- Delete all vehicles when entering zone
Config.UseRoutingBuckets = false -- Separate players in different buckets
Config.BlockCrossZoneDamage = false -- Only register kills within same zone

-- Reward Settings
Config.EnableKillStreaks = true -- Enable kill streak rewards
Config.EnablePerKillRewards = true -- Enable per-kill rewards
Config.EnableHeadshotBonuses = true -- Enable headshot bonus rewards

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
        coords = vector4(410.5369, -1513.8037, 29.2915, 40), -- x, y, z, radius
        reviveCoords = {
            vector4(381.5376, -1481.5315, 29.3416, 41.6205),
        },
        items = {
            { type = "weapon", name = "WEAPON_PISTOL", ammo = 100 }
        },
        rewards = {
            starting = {
                { type = "money", amount = 500 },
                -- { type = "item", name = "bread", count = 1 },
            },
            perKill = {
                { type = "money", amount = 500 },
                -- { type = "item", name = "bandage", count = 1 },
            },
            perHeadshot = {
                { type = "money", amount = 250 },
                -- { type = "item", name = "medkit", count = 1 },
            },
            killStreak = {
                [5] = {
                    { type = "money", amount = 1000 },
                    -- { type = "item", name = "armor", count = 1 },
                },
                [10] = {
                    { type = "money", amount = 2500 },
                    -- { type = "item", name = "weapon_carbinerifle", ammo = 200 },
                },
                [15] = {
                    { type = "money", amount = 5000 },
                    -- { type = "item", name = "medkit", count = 3 },
                }
            }
        }
    }
}
