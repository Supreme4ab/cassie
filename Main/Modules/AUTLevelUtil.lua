local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()

local Players = CommonUtil.GetService("Players")
local ReplicatedStorage = CommonUtil.GetService("ReplicatedStorage")

local AUTLevelUtil = {}

-- === CONFIG ===
AUTLevelUtil.AllowedAbilities = {
    "ABILITY_8881", "ABILITY_10019", "ABILITY_21", "ABILITY_10", "ABILITY_14"
}
local maxLevel = 200
local lastLevel = nil
local farmThread, levelWatcherThread
AUTLevelUtil.IsFarming = false
AUTLevelUtil.IsMonitoring = false

-- === HELPERS ===
function AUTLevelUtil.GetCurrentLevel()
    local label = Players.LocalPlayer.PlayerGui
        .UI.Gameplay.Character.Info:FindFirstChild("AbilityInfo")
    if label and label:IsA("TextLabel") then
        local match = string.match(label.Text, "LVL%s+(%d+)")
        return tonumber(match)
    end
    return nil
end

function AUTLevelUtil.BuildSellTable(allowed)
    local allowedAbilities = allowed or AUTLevelUtil.AllowedAbilities
    local sellTable = {}
    local shardFrame = Players.LocalPlayer
        .PlayerGui.UI.Menus["Black Market"].Frame.ShardConvert.Shards

    for _, abilityId in ipairs(allowedAbilities) do
        local frame = shardFrame:FindFirstChild(abilityId)
        if frame and frame:FindFirstChild("Button") then
            local amountLabel = frame.Button:FindFirstChild("Amount")
            local amount = tonumber(amountLabel and amountLabel.Text)
            if amount and amount > 0 then
                -- Sell up to 5, but not more than we have
                sellTable[abilityId] = math.clamp(amount, 1, 5)
            end
        end
    end

    return sellTable
end

-- === FARM LOOP ===
function AUTLevelUtil.RunFarmLoop()
    if farmThread and coroutine.status(farmThread) ~= "dead" then return end

    farmThread = task.spawn(function()
        while AUTLevelUtil.IsFarming do
            pcall(function()
                ReplicatedStorage.ReplicatedModules
                    .KnitPackage.Knit.Services.ShopService.RF.RollBanner
                    :InvokeServer(1, "UShards", 10)
            end)

            local sellTable = AUTLevelUtil.BuildSellTable(nil, AUTLevelUtil.ShardsPerAbility or 5)
            if next(sellTable) then
                pcall(function()
                    ReplicatedStorage.ReplicatedModules
                        .KnitPackage.Knit.Services.LevelService.RF.ConsumeShardsForXP
                        :InvokeServer(sellTable)
                end)
            end

            task.wait(0.1)
        end
        farmThread = nil
    end)
end

-- === LEVEL WATCHER ===
function AUTLevelUtil.RunLevelWatcher(onAscend, onMax)
    if levelWatcherThread and coroutine.status(levelWatcherThread) ~= "dead" then return end

    levelWatcherThread = task.spawn(function()
        while AUTLevelUtil.IsMonitoring do
            local level = AUTLevelUtil.GetCurrentLevel()
            if level and level ~= lastLevel then
                lastLevel = level
            end

            if level == maxLevel then
                if AUTLevelUtil.IsFarming then
                    AUTLevelUtil.IsFarming = false
                    if onMax then onMax() end
                end
                task.wait(5)
            elseif level and level < maxLevel then
                if not AUTLevelUtil.IsFarming then
                    AUTLevelUtil.IsFarming = true
                    if onAscend then onAscend() end
                    AUTLevelUtil.RunFarmLoop()
                end
                task.wait(1)
            else
                task.wait(1)
            end
        end
        levelWatcherThread = nil
    end)
end

function AUTLevelUtil.Reset()
    AUTLevelUtil.IsFarming = false
    AUTLevelUtil.IsMonitoring = false
    farmThread = nil
    levelWatcherThread = nil
end

return AUTLevelUtil
