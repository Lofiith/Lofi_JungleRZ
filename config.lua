Config = {}

Config.Framework = 'esx' -- Which framework: 'esx' or 'qbcore'

-- Position of the UI:
Config.UIPosition =
'center-right'                                          -- 'bottom-left', 'bottom-right', 'top-left', 'top-right', 'center-left', 'center-right', 'center-top'

Config.MarkerColor = { r = 255, g = 0, b = 0, a = 100 } -- Zone color

-- Global Blip Settings
Config.BlipSprite = 310
Config.BlipColor = 1
Config.BlipScale = 0.7

Config.Zones = {
    {
        name = "JungleRZ",
        coords = vector3(410.5369, -1513.8037, 29.2915),               -- placement of the zone
        radius = 40.0,
        spawnCoords = vector4(391.3817, -1477.2532, 29.3424, 34.4897), -- revive spawn cords
        items = {
            { name = "weapon_appistol", amount = 1 },
        },
        rewardStart = 10000,     -- first kill reward
        rewardIncrement = 10000, -- the increment amount per each kill
    },
    -- {
    --     name = "JungleZone2",
    --     coords = vector3(250.0, -750.0, 30.0),
    --     radius = 60.0,
    --     spawnCoords = vector4(250.0, -750.0, 30.0, 90.0),
    --     items = {
    --         { name = "weapon_smg", amount = 1 },
    --         { name = "water",      amount = 3 },
    --     },
    --     rewardStart = 5000,
    --     rewardIncrement = 5000,
    -- },
}