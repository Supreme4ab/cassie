-- Cassie Hub | AUT Level Utility Module (Fixed)
-- File: Main/Modules/AUTLevelUtil.lua

local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()

local Players = CommonUtil.GetService("Players")
local AUTLevelUtil = {}

AUTLevelUtil.AllowedAbilities = {
    "ABILITY_8881", "ABILITY_10019", "ABILITY_21", "ABILITY_10", "ABILITY_14"
}

local maxLevel = 200
local lastLevel = nil
local farmThread, levelWatcherThread
AUTLevelUtil.IsFarming = false
AUTLevelUtil.IsMonitoring = false
AUTLevelUtil.ShardsPerAbility = 5
AUTLevelUtil.Debug = false

function AUTLevelUtil.GetCurrentLevel()
    local gui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return nil end

    local label = gui:FindFirstChild("UI") and gui.UI:FindFirstChild("Gameplay")
    if label then
        label = label:FindFirstChild("Character")
        if label then
            label = label:FindFirstChild("Info")
            if label then
                label = label:FindFirstChild("AbilityInfo")
            end
        end
    end

    if label and label:IsA("TextLabel") then
        local match = string.match(label.Text, "LVL%s+(%d+)")
        return tonumber(match)
    end
    return nil
end

function AUTLevelUtil.BuildSellTable(allowed, shardsPerAbility)
    local allowedAbilities = allowed or AUTLevelUtil.AllowedAbilities
    local maxPerAbility = math.clamp(shardsPerAbility or 1, 1, 15)
    local sellTable = {}

    local gui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return sellTable end

    local shardFrame = gui:FindFirstChild("UI")
    if shardFrame then
        shardFrame = shardFrame:FindFirstChild("Menus")
        if shardFrame then
            shardFrame = shardFrame:FindFirstChild("Black Market")
            if shardFrame then
                shardFrame = shardFrame:FindFirstChild("Frame")
                if shardFrame then
                    shardFrame = shardFrame:FindFirstChild("ShardConvert")
                    if shardFrame then
                        shardFrame = shardFrame:FindFirstChild("Shards")
                    end
                end
            end
        end
    end

    if not shardFrame then return sellTable end

    for _, abilityId in ipairs(allowedAbilities) do
        local frame = shardFrame:FindFirstChild(abilityId)
        if frame and frame:FindFirstChild("Button") then
            local amountLabel = frame.Button:FindFirstChild("Amount")
            local amount = tonumber(amountLabel and amountLabel.Text)
            if amount and amount > 0 then
                sellTable[abilityId] = math.clamp(amount, 1, maxPerAbility)
            end
        end
    end

    return sellTable
end

function AUTLevelUtil.Log(message)
    if AUTLevelUtil.Debug then
        print("[Cassie AUT]:", message)
    end
end

function AUTLevelUtil.RunFarmLoop()
    if farmThread and coroutine.status(farmThread) ~= "dead" then return end

    local RollBanner = CommonUtil.GetKnitRemote("ShopService", "RF", "RollBanner")
    local ConsumeShards = CommonUtil.GetKnitRemote("LevelService", "RF", "ConsumeShardsForXP")

    farmThread = task.spawn(function()
        while true do
            if not AUTLevelUtil.IsFarming then break end

            pcall(function()
                if RollBanner then
                    RollBanner:InvokeServer(1, "UShards", 10)
                else
                    AUTLevelUtil.Log("RollBanner remote missing")
                end
            end)

            local sellTable = AUTLevelUtil.BuildSellTable(nil, AUTLevelUtil.ShardsPerAbility)
            if next(sellTable) then
                pcall(function()
                    if ConsumeShards then
                        ConsumeShards:InvokeServer(sellTable)
                    else
                        AUTLevelUtil.Log("ConsumeShards remote missing")
                    end
                end)
            end

            task.wait(0.1)
        end
        farmThread = nil
    end)
end

function AUTLevelUtil.RunLevelWatcher(onAscend, onMax)
    if levelWatcherThread and coroutine.status(levelWatcherThread) ~= "dead" then return end

    levelWatcherThread = task.spawn(function()
        while AUTLevelUtil.IsMonitoring do
            local level = AUTLevelUtil.GetCurrentLevel()
            if not level then task.wait(1) continue end

            if level ~= lastLevel then
                lastLevel = level
            end

            if level == maxLevel then
                if AUTLevelUtil.IsFarming then
                    AUTLevelUtil.IsFarming = false
                    if onMax then onMax() end
                end
                task.wait(5)
            elseif level < maxLevel then
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
