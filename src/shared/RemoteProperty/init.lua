local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)

local RemoteProperty = {}
RemoteProperty.deltaMiddleware = require(script.deltaMiddleware)
RemoteProperty.initializeMiddleware = require(script.initializeMiddleware)
RemoteProperty.loggerMiddleware = require(script.loggerMiddleware)

RemoteProperty.isTesting = false
RemoteProperty.isServer = RunService:IsServer()
RemoteProperty.__index = RemoteProperty

function RemoteProperty.new(instance, name, middlewares)
    local self = setmetatable({
        Changed = Signal.new();
        _remote = nil;
        _value = nil;
        _lastValue = nil;
        _lastRemoteValue = nil;
        _handler = function(...)
            return ...
        end;
    }, RemoteProperty)

    if middlewares then
        for i = #middlewares, 1, -1 do
            local middleware = middlewares[i]

            if RemoteProperty.isServer and middleware.outbound then
                self._handler = middleware.outbound(self._handler)
            elseif not RemoteProperty.isServer and middleware.inbound then
                self._handler = middleware.inbound(self._handler)
            end
        end
    end

    if RemoteProperty.isServer or RemoteProperty.isTesting then
        self._remote = Instance.new("RemoteEvent")
        self._remote.Name = name
        self._remote.Parent = instance

        self._playerAddedCon = Players.PlayerAdded:Connect(function(player)
            local initializedValue = self._handler(self._value, true)
            
            if initializedValue ~= nil then
                self._remote:FireClient(player, initializedValue)
            end
        end)
    else
        self._remote = instance:WaitForChild(name)
        self._remote.OnClientEvent:Connect(function(value)
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

function RemoteProperty:_processHandlerReturnValue(value, ...)
    -- If handler returned nothing, return early.
    if select("#", ...) == 0 then
        return
    end

    local remoteValue = ...

    if remoteValue ~= self._lastRemoteValue then
        if type(remoteValue) == "table" and not table.isfrozen(remoteValue) then
            table.freeze(remoteValue)
        end

        self._lastRemoteValue = remoteValue
        self._lastValue = value
        
        if RemoteProperty.isServer then
            self._value = value
            self._remote:FireAllClients(remoteValue)
            self.Changed:Fire(value)
        else
            self._value = remoteValue
            self.Changed:Fire(remoteValue)
        end
    end
end

function RemoteProperty:ForceReplicate()
    assert(RemoteProperty.isServer, "Can only force replicate on server")

    local initializedValue = self._handler(self._value, true)

    if initializedValue ~= nil then
        self._remote:FireAllClients(initializedValue)
    end
end

function RemoteProperty:_set(value)
    if value ~= self._lastValue then
        self:_processHandlerReturnValue(value, self._handler(value, false))
    end
end

-- Remote table should be frozen so it's guaranteed to never change.
function RemoteProperty:Set(value)
    assert(RemoteProperty.isServer, "Can only set on server")
    assert(type(value) ~= "table" or table.isfrozen(value), "Remote table must be frozen")
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