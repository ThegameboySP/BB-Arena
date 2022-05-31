local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Llama = require(ReplicatedStorage.Packages.Llama)

local RemoteProperty = {}
RemoteProperty.playerAddedSignal = Players.PlayerAdded
RemoteProperty.isTesting = false
RemoteProperty.isServer = RunService:IsServer()
RemoteProperty.__index = RemoteProperty

function RemoteProperty.new(instance, name, middlewares)
    local self = setmetatable({
        Changed = Signal.new();
        _remote = nil;
        _value = nil;
        _lastResolvedValue = nil;
        _handler = function(...)
            return ...
        end;
    }, RemoteProperty)

    if middlewares then
        for _, middleware in ipairs(middlewares) do
            if RemoteProperty.isServer and middleware.outbound then
                self._handler = middleware.outbound(self._handler)
            elseif not RemoteProperty.isServer and middleware.inbound then
                self._handler = middleware.inbound(self._handler)
            end
        end
    end

    if RemoteProperty.isServer then
        self._remote = Instance.new("RemoteEvent")
        self._remote.Name = name
        self._remote.Parent = instance

        self._playerAddedCon = RemoteProperty.playerAddedSignal:Connect(function(player)
            self._remote:FireClient(player, self._handler(self._value, true))
        end)
    else
        self._remote = instance:WaitForChild(name)
        self._remote.OnClientEvent:Connect(function(value)
            if type(value) == "table" then
                table.freeze(value)
            end

            self:_set(value)
        end)
    end

    return self
end

function RemoteProperty:Destroy()
    self._remote:Destroy()

    if self._playerAddedCon then
        self._playerAddedCon:Disconnect()
    end
end

function RemoteProperty:_set(value)
    assert(type(value) ~= "table" or table.isfrozen(value), "Remote table must be frozen")

    local lastResolvedValue = self._lastResolvedValue
    local resolvedValue = self._handler(value, false)
    
    if resolvedValue ~= nil and resolvedValue ~= lastResolvedValue then
        if resolvedValue == Llama.None then
            resolvedValue = nil
        end
        
        self._value = resolvedValue
        
        if RemoteProperty.isServer then
            self._remote:FireAllClients(resolvedValue)
        end
        
        self.Changed:Fire(resolvedValue, lastResolvedValue)
    end
end

function RemoteProperty:Set(value)
    assert(RemoteProperty.isServer, "Can only set on server")
    self:_set(value)
end

function RemoteProperty:Get()
    return self._value
end

function RemoteProperty:Observe(callback)
    local con = self.Changed:Connect(callback)
    if self._value then
        callback(self._value, nil)
    end

    return con
end

return RemoteProperty