--<< SERVICES & MODULES >>--
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()
local AUTLevelUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/AUTLevelUtil.lua"))()
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

--<< CONFIGURATION >>--
local CONFIG = {
    TITLE = "Cassie Hub | AUT | Level Farming",
    DEFAULT_KEY = "RightControl",
    SHARD_LIMIT = {
        MIN = 1,
        MAX = 15,
        DEFAULT = 5
    },
    CONFIG_PATH = "CassieHub_AUTLevel.fileformat",
    UPDATE_INTERVAL = 1,
    MAX_LEVEL = 200
}

--<< LOAD / SAVE SHARD CONFIG >>--
local function saveShardConfig(value)
    if writefile then
        writefile(CONFIG.CONFIG_PATH, HttpService:JSONEncode({Shards = value}))
    end
end

local function loadShardConfig()
    if isfile and isfile(CONFIG.CONFIG_PATH) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG.CONFIG_PATH))
        end)
        if success and result and result.Shards then
            return result.Shards
        end
    end
    return CONFIG.SHARD_LIMIT.DEFAULT
end

--<< REMOTES >>--
local function ascendAbility()
    local AscendRemote = ReplicatedStorage:WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit")
        :WaitForChild("Services"):WaitForChild("LevelService"):WaitForChild("RF"):WaitForChild("AscendAbility")
    AscendRemote:InvokeServer(1800)
end

--<< ATTRIBUTE UTIL >>--
local function getAbility()
    return Players.LocalPlayer:FindFirstChild("Data") and Players.LocalPlayer.Data:FindFirstChild("Ability")
end

function AUTLevelUtil.GetCurrentLevel()
    local ability = getAbility()
    return ability and ability:GetAttribute("AbilityLevel") or nil
end

function AUTLevelUtil.GetAbilityName()
    local ability = getAbility()
    return ability and ability:GetAttribute("AbilityName") or "Unknown"
end

function AUTLevelUtil.GetAscensionRank()
    local ability = getAbility()
    return ability and ability:GetAttribute("AscensionRank") or 0
end

--<< UI SETUP >>--
local Window = WindUI:CreateWindow({
    Title = CONFIG.TITLE,
    Icon = "zap",
    Author = "Cassie",
    Folder = "CassieHub",
    Size = UDim2.fromOffset(580, 460),
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 200,
})

local MainTab = Window:Tab({ Title = "Main", Icon = "zap" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "info" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- MAIN TAB: AUTO LEVEL SECTION
local levelSection = MainTab:Section({ Title = "Auto-Level" })

local currentLevelLabel = MainTab:Paragraph({
    Title = "Current Level",
    Desc = "Waiting...",
    Color = "Grey"  -- Same gray as WindUI toggle
})

local statusElement = nil
local lastStatusMode = nil

local function updateStatus(mode)
    if lastStatusMode == mode then return end
    lastStatusMode = mode

    if statusElement and typeof(statusElement.Destroy) == "function" then
        statusElement:Destroy()
    end

    local desc, color = "🔴 Disabled", "Red"
    if mode == "farming" then
        desc, color = "🟢 Farming", "Green"
    elseif mode == "idle" then
        desc, color = "🟠 Idle (Max Level)", "Orange"
    end

    statusElement = MainTab:Paragraph({
        Title = "Status",
        Desc = desc,
        Color = color
    })
end

local function showDialog(title, content)
    Window:Dialog({
        Title = title,
        Content = content,
        Buttons = {
            { Title = "OK", Callback = function() end }
        }
    })
end

-- AUTOFARM LOGIC
local function startFarming()
    AUTLevelUtil.Reset()
    AUTLevelUtil.IsMonitoring = true
    AUTLevelUtil.IsFarming = true

    updateStatus("farming")
    AUTLevelUtil.RunFarmLoop()

    AUTLevelUtil.RunLevelWatcher(
        function()
            updateStatus("farming")
        end,
        function()
            updateStatus("idle")
        end
    )
end

-- LEVEL MONITOR
task.spawn(function()
    local ability = getAbility()
    if not ability then return end
    while true do
        local level = ability:GetAttribute("AbilityLevel")
        if level then
            currentLevelLabel:SetDesc("Level: " .. tostring(level))
        else
            currentLevelLabel:SetDesc("Level: Unknown")
        end
        task.wait(CONFIG.UPDATE_INTERVAL)
    end
end)

-- SLIDER: SHARDS
local loadedShardValue = loadShardConfig()
MainTab:Slider({
    Title = "Shards Per Ability",
    Step = 1,
    Value = {
        Min = CONFIG.SHARD_LIMIT.MIN,
        Max = CONFIG.SHARD_LIMIT.MAX,
        Default = loadedShardValue
    },
    Callback = function(value)
        AUTLevelUtil.ShardsPerAbility = value
        saveShardConfig(value)
    end
})
AUTLevelUtil.ShardsPerAbility = loadedShardValue

-- TOGGLE: FARM
MainTab:Toggle({
    Title = "Level Autofarm",
    Desc = "Automatically farm and sell trait shards for XP",
    Default = false,
    Callback = function(enabled)
        if enabled then
            startFarming()
        else
            AUTLevelUtil.Reset()
            updateStatus("disabled")
        end
    end
})

-- MISC TAB: STAND INFO
MiscTab:Section({ Title = "Stand Info" })

local standNamePara = MiscTab:Paragraph({
    Title = "Stand",
    Desc = "Loading...",
    Color = "Grey"
})

local ascensionPara = MiscTab:Paragraph({
    Title = "Ascensions",
    Desc = "Loading...",
    Color = "Grey"
})

task.spawn(function()
    while true do
        standNamePara:SetDesc(AUTLevelUtil.GetAbilityName())
        ascensionPara:SetDesc(tostring(AUTLevelUtil.GetAscensionRank()))
        task.wait(2)
    end
end)

-- AUTO ASCEND TOGGLE
local autoAscendRunning = false
MiscTab:Toggle({
    Title = "Auto Ascend",
    Desc = "Automatically ascend when level 200 is reached.",
    Default = false,
    Callback = function(enabled)
        autoAscendRunning = enabled
        task.spawn(function()
            local lastAscension = AUTLevelUtil.GetAscensionRank()
            while autoAscendRunning do
                local level = AUTLevelUtil.GetCurrentLevel()
                if level and level >= CONFIG.MAX_LEVEL then
                    ascendAbility()
                end

                local currentAsc = AUTLevelUtil.GetAscensionRank()
                if currentAsc > lastAscension then
                    lastAscension = currentAsc
                    task.wait(0.5)
                    startFarming()
                    break
                end

                task.wait(1)
            end
        end)
    end
})

-- SETTINGS TAB
local transparencyState = false
SettingsTab:Button({
    Title = "Toggle Transparency",
    Desc = "Toggle blur background",
    Callback = function()
        transparencyState = not transparencyState
        Window:ToggleTransparency(transparencyState)
    end
})

SettingsTab:Button({
    Title = "Dark Theme",
    Desc = "Switch to Dark Theme",
    Callback = function()
        WindUI:SetTheme("Dark")
    end
})
SettingsTab:Button({
    Title = "Light Theme",
    Desc = "Switch to Light Theme",
    Callback = function()
        WindUI:SetTheme("Light")
    end
})

SettingsTab:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Bind a key to show/hide UI",
    Value = CONFIG.DEFAULT_KEY,
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v] or Enum.KeyCode[CONFIG.DEFAULT_KEY])
    end
})

-- INIT
showDialog("Cassie Hub", "AUT Level Farm Ready!")
Window:SelectTab(1)
