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

return CommonUtil
