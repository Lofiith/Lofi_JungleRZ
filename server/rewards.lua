local rewardHandlers = {}

local function processReward(src, reward)
    if not reward or not reward.type then return end
    
    if reward.type == "money" then
        TriggerEvent("jungleRZ:framework:giveMoney", src, reward.amount or 0)
    elseif reward.type == "item" then
        TriggerEvent("jungleRZ:framework:giveItem", src, reward.name, reward.count or 1)
    elseif reward.type == "weapon" then
        TriggerEvent("jungleRZ:framework:giveWeapon", src, reward.name, reward.ammo or 0)
    end
end

local function processRewards(src, rewards)
    if not rewards or type(rewards) ~= "table" then return end
    
    for _, reward in ipairs(rewards) do
        processReward(src, reward)
    end
end

function rewardHandlers.giveStartingRewards(src, zone)
    if not zone.rewards or not zone.rewards.starting then return end
    processRewards(src, zone.rewards.starting)
end

function rewardHandlers.giveKillRewards(src, zone, playerStats)
    if not zone.rewards then return 0 end
    
    local totalReward = 0
    
    if Config.EnablePerKillRewards and zone.rewards.perKill then
        processRewards(src, zone.rewards.perKill)
        for _, reward in ipairs(zone.rewards.perKill) do
            if reward.type == "money" then
                totalReward = totalReward + (reward.amount or 0)
            end
        end
    end
    
    if Config.EnableKillStreaks and zone.rewards.killStreak and zone.rewards.killStreak[playerStats.kills] then
        processRewards(src, zone.rewards.killStreak[playerStats.kills])
        for _, reward in ipairs(zone.rewards.killStreak[playerStats.kills]) do
            if reward.type == "money" then
                totalReward = totalReward + (reward.amount or 0)
            end
        end
        TriggerClientEvent("jungleRZ:killStreak", src, playerStats.kills, zone.rewards.killStreak[playerStats.kills])
    end
    
    return totalReward
end

function rewardHandlers.giveHeadshotRewards(src, zone)
    if not Config.EnableHeadshotBonuses or not zone.rewards or not zone.rewards.perHeadshot then return 0 end
    
    processRewards(src, zone.rewards.perHeadshot)
    
    local headshotBonus = 0
    for _, reward in ipairs(zone.rewards.perHeadshot) do
        if reward.type == "money" then
            headshotBonus = headshotBonus + (reward.amount or 0)
        end
    end
    
    return headshotBonus
end

function rewardHandlers.getZoneConfig(zoneName)
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName then
            return zone
        end
    end
    return nil
end

return rewardHandlers
