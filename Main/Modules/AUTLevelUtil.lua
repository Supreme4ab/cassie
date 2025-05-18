-- File: Main/Modules/AUTLevelUtil.lua

local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()
local Players = CommonUtil.GetService("Players")
local ReplicatedStorage = CommonUtil.GetService("ReplicatedStorage")

local AUTLevelUtil = {}

-- Parses current level from AbilityInfo label
function AUTLevelUtil.GetCurrentLevel()
    local label = Players.LocalPlayer.PlayerGui.UI.Gameplay.Character.Info:FindFirstChild("AbilityInfo")
    if label and label:IsA("TextLabel") then
        local match = string.match(label.Text, "LVL%s+(%d+)")
        return tonumber(match)
    end
    return nil
end

-- Builds a sell table for only allowed abilities (limited to 1 per)
function AUTLevelUtil.BuildSellTable(allowedAbilities)
    local sellTable = {}
    local shardFrame = Players.LocalPlayer
        .PlayerGui.UI.Menus["Black Market"].Frame.ShardConvert.Shards

    for _, abilityId in ipairs(allowedAbilities) do
        local abilityFrame = shardFrame:FindFirstChild(abilityId)
        if abilityFrame and abilityFrame:FindFirstChild("Button") then
            local amountLabel = abilityFrame.Button:FindFirstChild("Amount")
            local amount = tonumber(amountLabel and amountLabel.Text)
            if amount and amount > 0 then
                sellTable[abilityId] = 1
            end
        end
    end

    return sellTable
end

return AUTLevelUtil
