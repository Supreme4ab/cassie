-- Cassie Hub | AUT | Level Farming (Final Fixed + Status Cleanup)

--<< SERVICES & MODULES >>--
local HttpService = game:GetService("HttpService")

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
    UPDATE_INTERVAL = 1
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
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

--<< UI ELEMENTS >>--
local currentLevelLabel = MainTab:Paragraph({
    Title = "Current Level",
    Desc = "Waiting...",
    Color = "Grey"
})

-- Store the status element reference directly
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

--<< DIALOG HELPER >>--
local function showDialog(title, content)
    Window:Dialog({
        Title = title,
        Content = content,
        Buttons = {
            { Title = "OK", Callback = function() end }
        }
    })
end

--<< FARM CONTROL LOGIC >>--
local function startFarming()
    AUTLevelUtil.Reset()
    AUTLevelUtil.IsMonitoring = true
    AUTLevelUtil.IsFarming = true

    updateStatus("farming")
    AUTLevelUtil.RunFarmLoop()

    AUTLevelUtil.RunLevelWatcher(
        function()
            if AUTLevelUtil.IsFarming then
                showDialog("Ascension Detected", "Player ascended — resuming farm!")
                updateStatus("farming")
            end
        end,
        function()
            if AUTLevelUtil.IsMonitoring then
                showDialog("Max Level", "Player reached level 200 — farming paused.")
                updateStatus("idle")
            end
        end
    )
end

--<< LEVEL MONITORING TASK >>--
task.spawn(function()
    while true do
        local level = AUTLevelUtil.GetCurrentLevel()
        if level then
            currentLevelLabel:SetDesc("Level: " .. tostring(level))
        else
            currentLevelLabel:SetDesc("Level: Unknown")
        end
        task.wait(CONFIG.UPDATE_INTERVAL)
    end
end)

--<< SHARDS SLIDER >>--
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

--<< TOGGLE: FARM >>--
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

--<< SETTINGS TAB OPTIONS >>--
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

--<< WELCOME >>--
showDialog("Cassie Hub", "AUT Level Farm Ready!")
Window:SelectTab(1)
