local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()
local ReplicatedStorage = CommonUtil.GetService("ReplicatedStorage")
local Players = CommonUtil.GetService("Players")
local LocalPlayer = CommonUtil.GetLocalPlayer()

local Knit = require(ReplicatedStorage:WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit"))
local ShopService = Knit.GetService("ShopService")
local LevelService = Knit.GetService("LevelService")

local AUTLevelUtil = {
    IsFarming = false,
    IsMonitoring = false,
    ShardsPerAbility = 5
}

local allowedAbilities = {
    "ABILITY_8881", "ABILITY_10019", "ABILITY_21", "ABILITY_10", "ABILITY_14"
}

function AUTLevelUtil:GetCurrentLevel()
    local abilityInfo = LocalPlayer.PlayerGui.UI.Gameplay.Character.Info:FindFirstChild("AbilityInfo")
    if not abilityInfo or not abilityInfo:IsA("TextLabel") then return nil end

    local level = tonumber(abilityInfo.Text:match("LVL (%d+)"))
    return level
end

function AUTLevelUtil:BuildSellTable()
    local shardFrame = LocalPlayer.PlayerGui.UI.Menus["Black Market"].Frame.ShardConvert.Shards
    local shardTable = {}

    for _, ability in ipairs(allowedAbilities) do
        local button = shardFrame:FindFirstChild(ability)
        if button then
            local amountLabel = button:FindFirstChild("Amount")
            if amountLabel and tonumber(amountLabel.Text) and tonumber(amountLabel.Text) >= 1 then
                shardTable[ability] = math.clamp(AUTLevelUtil.ShardsPerAbility, 1, tonumber(amountLabel.Text))
            end
        end
    end

    return shardTable
end

function AUTLevelUtil:RunFarmLoop()
    task.spawn(function()
        while AUTLevelUtil.IsFarming do
            local args = {
                [1] = 1,
                [2] = "UShards",
                [3] = 10
            }

            ShopService.RF.RollBanner:InvokeServer(unpack(args))

            local shardTable = AUTLevelUtil:BuildSellTable()
            if next(shardTable) then
                LevelService.RF.ConsumeShardsForXP:InvokeServer({shardTable})
            end

            task.wait(0.1)
        end
    end)
end

print("[Watcher] Running...")

function AUTLevelUtil:RunLevelWatcher(onAscend, onMaxLevel)
    task.spawn(function()
        while AUTLevelUtil.IsMonitoring do
            local level = AUTLevelUtil:GetCurrentLevel()
            print("[Watcher] Current Level:", level)
            if level == 200 then
                print("[Watcher] Max level reached, triggering onMaxLevel")
                AUTLevelUtil.IsFarming = false
                onMaxLevel()
                repeat
                    task.wait(1)
                    level = AUTLevelUtil:GetCurrentLevel()
                until level and level < 200
                print("[Watcher] Ascension detected, triggering onAscend")
                AUTLevelUtil.IsFarming = true
                onAscend()
            end
            task.wait(1)
        end
    end)
end

function AUTLevelUtil:Reset()
    AUTLevelUtil.IsFarming = false
    AUTLevelUtil.IsMonitoring = false
end

return AUTLevelUtil
