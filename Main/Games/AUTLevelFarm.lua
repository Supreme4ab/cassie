local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()
local AUTLevelUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/AUTLevelUtil.lua"))()

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Cassie Hub | AUT | Level Farming",
    SubTitle = "v1.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "zap" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

Tabs.Main:AddToggle("AutoFarm", {
    Title = "AutoFarm",
    Default = false
}):OnChanged(function()
    local enabled = Options.AutoFarm.Value
    if enabled then
        print("🟢 Cassie AUT Level Farm enabled.")
        AUTLevelUtil.IsFarming = true
        AUTLevelUtil.IsMonitoring = true
        AUTLevelUtil.RunFarmLoop()
        AUTLevelUtil.RunLevelWatcher()
    else
        print("🔴 Cassie AUT Level Farm disabled.")
        AUTLevelUtil.IsFarming = false
        AUTLevelUtil.IsMonitoring = false
    end
end)

Fluent:Notify({
    Title = "Cassie Hub",
    Content = "AUT Level Farm Ready!",
    Duration = 4
})

Window:SelectTab(1)
