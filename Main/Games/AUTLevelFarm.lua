local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()
local AUTLevelUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/AUTLevelUtil.lua"))()
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Config
local CONFIG = {
    TITLE = "Cassie Hub | AUT | Level Farming",
    DEFAULT_KEY = "RightControl",
    SHARD_LIMIT = {
        MIN = 1,
        MAX = 15,
        DEFAULT = 5
    }
}

local Services = CommonUtil.Services

-- Window
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

-- Tabs
local MainTab = Window:Tab({ Title = "Main", Icon = "zap" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "sparkles" })

-- Misc Section (Stand Info)
local standSection = MiscTab:Section({
    Title = "Stand",
    TextXAlignment = "Center"
})

local standNameParagraph = MiscTab:Paragraph({
    Title = "Current Stand",
    Desc = "Loading...",
    Color = "Grey"
})

local ascensionParagraph = MiscTab:Paragraph({
    Title = "Ascensions",
    Desc = "Loading...",
    Color = "Grey"
})

task.spawn(function()
    local success, abilityValue = pcall(function()
        return Services.Players.LocalPlayer:WaitForChild("Data"):WaitForChild("Ability")
    end)

    if success and abilityValue then
        while true do
            local name = abilityValue:GetAttribute("AbilityName") or "Unknown"
            local rank = abilityValue:GetAttribute("AscensionRank") or 0

            standNameParagraph:SetDesc(name)
            ascensionParagraph:SetDesc(tostring(rank) .. " Ascensions")

            task.wait(1)
        end
    else
        standNameParagraph:SetDesc("Unavailable")
        ascensionParagraph:SetDesc("N/A")
    end
end)

-- Paragraphs
local currentLevelLabel = MainTab:Paragraph({
    Title = "Current Level",
    Desc = "Waiting...",
    Color = "Grey"
})

local statusParagraph

-- Rebuild status paragraph
local function updateStatus(mode)
    if statusParagraph then statusParagraph:Destroy() end

    local desc, color = "🔴 Disabled", "Red"
    if mode == "farming" then
        desc, color = "🟢 Farming", "Green"
    elseif mode == "idle" then
        desc, color = "🟠 Idle (Max Level)", "Orange"
    end

    statusParagraph = MainTab:Paragraph({
        Title = "Status",
        Desc = desc,
        Color = color
    })
end

-- Dialog Helper
local function showDialog(title, content)
    Window:Dialog({
        Title = title,
        Content = content,
        Buttons = {
            { Title = "OK", Callback = function() end }
        }
    })
end

-- Start Farm
local function startFarming()
    updateStatus("farming")
    AUTLevelUtil.IsFarming = true
    AUTLevelUtil.IsMonitoring = true
    AUTLevelUtil.RunFarmLoop()
    AUTLevelUtil.RunLevelWatcher(
        function()
            showDialog("Ascension Detected", "Player ascended — resuming farm!")
            updateStatus("farming")
        end,
        function()
            showDialog("Max Level", "Player reached level 200 — farming paused.")
            updateStatus("idle")
        end
    )
end

-- Live Level Tracking
task.spawn(function()
    while true do
        local level = AUTLevelUtil.GetCurrentLevel()
        if level then
            currentLevelLabel:SetDesc("Level: " .. tostring(level))
        else
            currentLevelLabel:SetDesc("Level: Unknown")
        end
        task.wait(1)
    end
end)

-- Shards Slider
MainTab:Slider({
    Title = "Shards Per Ability",
    Step = 1,
    Value = {
        Min = CONFIG.SHARD_LIMIT.MIN,
        Max = CONFIG.SHARD_LIMIT.MAX,
        Default = CONFIG.SHARD_LIMIT.DEFAULT
    },
    Callback = function(value)
        AUTLevelUtil.ShardsPerAbility = value
    end
})
AUTLevelUtil.ShardsPerAbility = CONFIG.SHARD_LIMIT.DEFAULT

-- Autofarm Toggle
local autoToggleDebounce = false
MainTab:Toggle({
    Title = "Level Autofarm",
    Desc = "Automatically farm and sell trait shards for XP",
    Default = false,
    Callback = function(enabled)
        if autoToggleDebounce then return end
        autoToggleDebounce = true

        if enabled then
            startFarming()
        else
            updateStatus("disabled")
            AUTLevelUtil.Reset()
        end

        task.wait(0.25)
        autoToggleDebounce = false
    end
})

-- Transparency Toggle
local transparencyState = false
SettingsTab:Button({
    Title = "Toggle Transparency",
    Desc = "Toggle blur background",
    Callback = function()
        transparencyState = not transparencyState
        Window:ToggleTransparency(transparencyState)
    end
})

-- Theme Switchers
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

-- Keybind Config
SettingsTab:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Bind a key to show/hide UI",
    Value = CONFIG.DEFAULT_KEY,
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v] or Enum.KeyCode[CONFIG.DEFAULT_KEY])
    end
})

-- Initial Welcome Dialog
showDialog("Cassie Hub", "AUT Level Farm Ready!")

Window:SelectTab(1)
