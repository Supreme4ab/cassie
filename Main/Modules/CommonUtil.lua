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
    local Knit = CommonUtil.GetService("ReplicatedStorage"):WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit")
    return Knit.Services[serviceName][remoteType][remoteName]
end

return CommonUtil
