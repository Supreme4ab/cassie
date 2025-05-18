local Services = {}
setmetatable(Services, {
    __index = function(_, serviceName)
        local service = game:GetService(serviceName)
        rawset(Services, serviceName, service)
        return service
    end
})

local function GetKnitRemote(service, remoteType, remoteName)
    return Services.ReplicatedStorage
        :WaitForChild("ReplicatedModules")
        :WaitForChild("KnitPackage")
        :WaitForChild("Knit")
        :WaitForChild("Services")
        :WaitForChild(service)
        :WaitForChild(remoteType)
        :WaitForChild(remoteName)
end

return {
    Services = Services,
    GetKnitRemote = GetKnitRemote,
}
