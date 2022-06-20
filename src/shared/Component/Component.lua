local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)

local returnName = function(t)
    return t._name
end

local Component = setmetatable({}, {__tostring = returnName})
Component.__tostring = returnName
Component.__index = Component

local IS_SERVER = RunService:IsServer()

function Component:__fireStateChanged(...)
    for _, player in pairs(Players:GetPlayers()) do
        if self.__initializedPlayers[player] then
            self.__remote:FireClient(player, ...)
        else
            self.__initializedPlayers[player] = true
            self.__remote:FireClient(player, self.State)
        end
    end
end

function Component:extend(name, mergeWith)
    local new = table.clone(self)
    
    new.new = function(instance, config)
        local this = setmetatable({
            Instance = instance;
            Config = config;
            State = table.freeze({});
            Changed = Signal.new();

            __remote = nil;
            __initializedPlayers = {};
            __toDestroy = {};
        }, new)

        if IS_SERVER then
            CollectionService:AddTag(instance, "ServerComponent")

            this.__connection = Players.PlayerAdded:Connect(function(player)
                this.__initializedPlayers[player] = true
                this.__remote:FireClient(player, this.State)
            end)

            this.__remote = Instance.new("RemoteEvent")
            this.__remote.Name = "UpdateState"
            this.__remote.Parent = instance
        elseif CollectionService:HasTag(instance, "ServerComponent") then
            this.__remote = instance:FindFirstChild("UpdateState")

            if this.__remote == nil then
                warn(string.format("UpdateState remote not found under %s for %s ", this.Instance:GetFullName(), tostring(this)))
            else
                this.__remote.OnClientEvent:Connect(function(delta)
                    this:SetState(delta)
                end)
            end
        end

        return this
    end

    if mergeWith then
        for k, v in pairs(mergeWith) do
            new[k] = v
        end
    end

    new.__index = new
    new._name = name

    return new
end

function Component:ForceReplicate()
    self.__remote:FireAllClients(self.State)
end

function Component:RemoteEvent(name)
    if IS_SERVER then
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = self.Instance
        table.insert(self.__toDestroy, remoteEvent)

        return remoteEvent
    else
        local remoteEvent = self.Instance:FindFirstChild(name)
            or error(("No child named %s under %s"):format(name, self.Instance:GetFullName()))
        
        table.insert(self.__toDestroy, remoteEvent)

        return remoteEvent
    end
end

function Component:Signal()
    local signal = Signal.new()
    table.insert(self.__toDestroy, signal)
    return signal
end

function Component:SetState(delta)
    local oldState = self.State
    local newState = table.clone(oldState)
    for k, v in pairs(delta) do
        newState[k] = v
    end

    self.State = table.freeze(newState)

    if IS_SERVER then
        local changed = {}
        
        for k, v in pairs(delta) do
            if oldState[k] ~= v then
                changed[k] = v
            end
        end

        if next(changed) then
            self:__fireStateChanged(changed)
        end
    end

    self.Changed:Fire(newState, oldState)
end

function Component:Destroy()
    xpcall(self.OnDestroy, function(msg)
        task.spawn(msg, debug.traceback(msg, 2))
    end, self)

    self.Changed:Destroy()

    if self.__remote then
        self.__remote:Destroy()
    end
    
    for _, remote in self.__toDestroy do
        remote:Destroy()
    end
end

function Component:OnDestroy()

end

function Component:OnInit()

end

function Component:OnStart()

end

return Component