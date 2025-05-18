local Services = setmetatable({}, {
    __index = function(self, name)
        local s = game:GetService(name)
        rawset(self, name, s)
        return s
    end
})

local CommonUtil = {}

function CommonUtil.GetService(name)
    return Services[name]
end

function CommonUtil.WaitForService(name, timeout)
    return game:WaitForChild(name, timeout or 5)
end

function CommonUtil.GetLocalPlayer()
    return Services.Players.LocalPlayer
end

function CommonUtil.GetKnitRemote(serviceName, remoteType, remoteName)
    local success, result = pcall(function()
        local Knit = CommonUtil.GetService("ReplicatedStorage"):WaitForChild("ReplicatedModules", 5):WaitForChild("KnitPackage", 5):WaitForChild("Knit", 5)
        return Knit.Services[serviceName][remoteType][remoteName]
    end)
    return success and result or nil
end

return CommonUtil
