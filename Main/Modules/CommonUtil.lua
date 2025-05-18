local Services = setmetatable({}, {
    __index = function(self, service)
        local s = game:GetService(service)
        rawset(self, service, s)
        return s
    end
})

local CommonUtil = {}

function CommonUtil.GetService(name)
    return Services[name]
end

function CommonUtil.GetLocalPlayer()
    return Services.Players.LocalPlayer
end

return CommonUtil
