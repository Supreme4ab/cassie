local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()
local Services = CommonUtil.Services

local AUTLevelUtil = {}

AUTLevelUtil.ShardsPerAbility = 5
AUTLevelUtil.IsFarming = false
AUTLevelUtil.IsMonitoring = false

local allowedAbilities = {
    "ABILITY_8881", "ABILITY_10019", "ABILITY_21", "ABILITY_10", "ABILITY_14"
}

-- Parses level number from text
function AUTLevelUtil.GetCurrentLevel()
    local label = Services.Players.LocalPlayer
        .PlayerGui:WaitForChild("UI")
        .Gameplay:WaitForChild("Character")
        .Info:WaitForChild("AbilityInfo")

    local text = label.Text:match("LVL%s+(%d+)")
    return tonumber(text)
end

-- Builds a sell dictionary based on player UI
function AUTLevelUtil.BuildShardSellData()
    local shardPanel = Services.Players.LocalPlayer
        .PlayerGui.UI.Menus["Black Market"]
        .Frame.ShardConvert.Shards

    local data = {}
    for _, ability in ipairs(allowedAbilities) do
        local button = shardPanel:FindFirstChild(ability)
        if button then
            local amt = tonumber(button.Button.Amount.Text)
            if amt and amt >= AUTLevelUtil.ShardsPerAbility then
                data[ability] = AUTLevelUtil.ShardsPerAbility
            end
        end
    end

    return next(data) and data or nil
end

-- Farming loop
function AUTLevelUtil.RunFarmLoop()
    task.spawn(function()
        while AUTLevelUtil.IsFarming do
            local rollArgs = { 1, "UShards", 10 }
            local sellData = AUTLevelUtil.BuildShardSellData()

            CommonUtil.GetKnitRemote("ShopService", "RF", "RollBanner"):InvokeServer(unpack(rollArgs))

            if sellData then
                CommonUtil.GetKnitRemote("LevelService", "RF", "ConsumeShardsForXP"):InvokeServer({ sellData })
            end

            task.wait(0.1)
        end
    end)
end

-- Watcher for auto-stopping at level 200 and resuming on ascension
function AUTLevelUtil.RunLevelWatcher(onAscend, onMaxLevel)
    task.spawn(function()
        local wasMax = false

        while AUTLevelUtil.IsMonitoring do
            local level = AUTLevelUtil.GetCurrentLevel()
            if level == 200 and not wasMax then
                wasMax = true
                AUTLevelUtil.IsFarming = false
                if onMaxLevel then onMaxLevel() end
            elseif wasMax and level and level < 200 then
                wasMax = false
                AUTLevelUtil.IsFarming = true
                if onAscend then onAscend() end
            end
            task.wait(1)
        end
    end)
end

function AUTLevelUtil.Reset()
    AUTLevelUtil.IsFarming = false
    AUTLevelUtil.IsMonitoring = false
end

return AUTLevelUtil
