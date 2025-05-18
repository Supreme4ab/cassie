-- File: Main/Modules/AUTLevelUtil.lua

local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()

local Players = CommonUtil.GetService("Players")
local ReplicatedStorage = CommonUtil.GetService("ReplicatedStorage")

local AUTLevelUtil = {}

-- Whitelisted trait shard types
AUTLevelUtil.AllowedAbilities = {
    "ABILITY_8881",
    "ABILITY_10019",
    "ABILITY_21",
    "ABILITY_10",
    "ABILITY_14"
}

-- Parse level from rich text
function AUTLevelUtil.GetCurrentLevel()
    local label = Players.LocalPlayer.PlayerGui
        .UI.Gameplay.Character.Info:FindFirstChild("AbilityInfo")

    if label and label:IsA("TextLabel") then
        local match = string.match(label.Text, "LVL%s+(%d+)")
        return tonumber(match)
    end
    return nil
end

-- Build sell table for allowedAbilities (1 shard each)
function AUTLevelUtil.BuildSellTable()
    local sellTable = {}
    local shardFrame = Players.LocalPlayer
        .PlayerGui.UI.Menus["Black Market"].Frame.ShardConvert.Shards

    for _, abilityId in ipairs(AUTLevelUtil.AllowedAbilities) do
        local frame = shardFrame:FindFirstChild(abilityId)
        if frame and frame:FindFirstChild("Button") then
            local amountLabel = frame.Button:FindFirstChild("Amount")
            local amount = tonumber(amountLabel and amountLabel.Text)
            if amount and amount > 0 then
                sellTable[abilityId] = 1
            end
        end
    end
    return sellTable
end

-- Internal threads
local farmThread, levelWatcherThread
local maxLevel = 200
local lastLevel = nil

function AUTLevelUtil.RunFarmLoop()
    if farmThread then return end

    farmThread = task.spawn(function()
        while AUTLevelUtil.IsFarming do
            pcall(function()
                ReplicatedStorage.ReplicatedModules
                    .KnitPackage.Knit.Services.ShopService.RF.RollBanner
                    :InvokeServer(1, "UShards", 10)
            end)

            local sellTable = AUTLevelUtil.BuildSellTable()
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

function AUTLevelUtil.RunLevelWatcher()
    if levelWatcherThread then return end

    levelWatcherThread = task.spawn(function()
        while AUTLevelUtil.IsMonitoring do
            local level = AUTLevelUtil.GetCurrentLevel()
            if level and level ~= lastLevel then
                lastLevel = level
            end

            if level == maxLevel then
                if AUTLevelUtil.IsFarming then
                    AUTLevelUtil.IsFarming = false
                    print("🟨 Max level reached. Halting farm.")
                end
                print("Player has reached maximum level.")
                task.wait(5)
            elseif level and level < maxLevel then
                if not AUTLevelUtil.IsFarming then
                    print("🟩 Ascended detected. Resuming farm.")
                    AUTLevelUtil.IsFarming = true
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

-- State flags
AUTLevelUtil.IsFarming = false
AUTLevelUtil.IsMonitoring = false

return AUTLevelUtil
