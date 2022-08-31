local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")
local Players = game:GetService("Players")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local RemoteEvent = require(ReplicatedStorage.Common.RemoteEvent)
local RemoteProperty = require(ReplicatedStorage.Common.RemoteProperty)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)

local Status = {
    Uninitialized = 0;
    Initializing = 1;
    Initialized = 2;
}

local Root = {}
Root.__index = Root
Root.isServer = RunService:IsServer()

function Root.new(replicatedContainer)
    return setmetatable({
        services = {};
        serverServices = nil;
        _status = Status.Uninitialized;
        _startedSignal = Signal.new();
        _root = nil;
        _replicatedContainer = replicatedContainer or ReplicatedStorage;

        _infosByUserId = {};
        _userIdsByName = {};
    }, Root)
end

function Root:GetFullNameByUserId(userId)
    return self:GetUserInfoByUserId(userId)
        :andThen(function(info)
            return getFullPlayerName(info)
        end, function()
            return "#" .. tostring(userId)
        end)
end

function Root:GetUserInfoByUserId(userId)
    local cached = self._infosByUserId[userId]
    
    if Promise.is(cached) then
        return cached
    elseif cached then
        return Promise.resolve(cached)
    end

    self._infosByUserId[userId] = Promise.new(function(resolve)
        local info = UserService:GetUserInfosByUserIdsAsync({userId})[1]

        self._infosByUserId[userId] = table.freeze(info)
        self._userIdsByName[info.Username] = userId

        resolve(info)
    end):catch(function(err)
        warn(err)
        self._infosByUserId[userId] = nil
    end)

    return self._infosByUserId[userId]
end

function Root:GetUserIdByName(name)
    local cached = self._userIdsByName[name]

    if Promise.is(cached) then
        return cached
    elseif cached then
        return Promise.resolve(cached)
    end

    self._userIdsByName[name] = Promise.new(function(resolve)
        local userId = Players:GetUserIdFromNameAsync(name)
        self._userIdsByName[name] = userId

        resolve(userId)
    end)

    return self._userIdsByName[name]
end

function Root:RegisterServices(services)
    for name, service in pairs(services) do
        self:RegisterService(name, service)
    end
end

function Root:RegisterService(name, service)
    if self.services[name] then
        error(("Duplicate service %q"):format(name))
    end

    self.services[name] = service
end

function Root:RegisterServicesIn(root)
    for _, child in pairs(root:GetChildren()) do
        if child:IsA("ModuleScript") then
            self:RegisterService(child.Name, require(child))
        elseif child:IsA("Folder") then
            self:RegisterServicesIn(child)
        end
    end
end

function Root:GetService(name)
    if self._status == Status.Uninitialized then
        error("Cannot call GetService until Root is initialized")
    end

    return self.services[name] or error("No service named " .. name)
end

function Root:GetSingleton(name)
    if self.isServer then
        return self:GetService(name .. "Service")
    else
        return self:GetService(name .. "Controller")
    end
end

function Root:GetServerService(name)
    if self._status == Status.Uninitialized then
        error("Cannot call GetServerService until Root is initialized")
    end

    return
        if self.serverServices
        then self.serverServices[name] or error("No server service named " .. name)
        else nil
end

function Root:Start(tbl)
    assert(self._status == Status.Uninitialized, "Already started root")

    task.spawn(function()
        self._status = Status.Initializing
        
        if self.isServer then
            self._root = Instance.new("Folder")
            self._root.Name = "Root_Replication"
            self._root.Parent = self._replicatedContainer
        else
            self._root = self._replicatedContainer:WaitForChild("Root_Replication")
    
            if not self._root:GetAttribute("Replicated") then
                self._root:GetAttributeChangedSignal("Replicated"):Wait()
            end
        end
    
        if self.isServer then
            for name, service in pairs(self.services) do
                local folder = Instance.new("Folder")
                folder.Name = name
    
                for key, value in pairs(service.Client or {}) do
                    if value.type == "__remoteEvent" then
                        local remoteEvent = Instance.new("RemoteEvent")
                        remoteEvent.Name = "RemoteEvent_" .. key
                        remoteEvent.Parent = folder

                        service.Client[key] = RemoteEvent.new(remoteEvent)
                    elseif value.type == "__remoteProperty" then
                        service.Client[key] = RemoteProperty.new(
                            folder,
                            "RemoteProperty_" .. key
                        )

                        service.Client[key]:Set(value.default)
                    end
                end
    
                folder.Parent = self._root
            end
        else
            self.serverServices = {}
    
            for _, folder in ipairs(self._root:GetChildren()) do
                local serverService = {}
                self.serverServices[folder.Name] = serverService
    
                for _, child in ipairs(folder:GetChildren()) do
                    if child.Name:find("RemoteEvent") then
                        serverService[child.Name:match("RemoteEvent_(.+)$")] = RemoteEvent.new(child)
                    elseif child.Name:find("RemoteProperty") then
                        serverService[child.Name:match("RemoteProperty_(.+)$")] = RemoteProperty.new(folder, child.Name)
                    end
                end
            end
        end
    
        local servicesOrder = {}
        for _, service in self.services do
            table.insert(servicesOrder, service)
        end

        table.sort(servicesOrder, function(a, b)
            return (a.Priority or 0) > (b.Priority or 0)
        end)
        
        for _, service in servicesOrder do
            if service.OnInit then
                xpcall(service.OnInit, function(err)
                    task.spawn(error, debug.traceback(err, 2))
                end, service, tbl)
            end
        end
    
        for _, service in servicesOrder do
            if service.OnStart then
                task.spawn(service.OnStart, service, tbl)
            end
        end
    
        self._root:SetAttribute("Replicated", true)

        self._status = Status.Initialized
        self._startedSignal:Fire()
    end)

    return self:OnStart()
end

function Root:OnStart()
    if self._status == Status.Initialized then
        return Promise.resolve()
    else
        return Promise.fromEvent(self._startedSignal)
    end
end

function Root.remoteEvent()
    return {
        type = "__remoteEvent";
    }
end

function Root.remoteProperty(default)
    return {
        type = "__remoteProperty";
        default = default;
    }
end

return Root.new()