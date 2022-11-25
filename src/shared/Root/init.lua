local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")
local Players = game:GetService("Players")

local Matter = require(ReplicatedStorage.Packages.Matter)
local Promise = require(ReplicatedStorage.Packages.Promise)
local MatterComponents = require(ReplicatedStorage.Common.MatterComponents)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local bindSignals = require(script.bindSignals)
local getSystems = require(script.getSystems)
local Services = require(script.Services)
local Status = require(script.Status)

local SharedServices = ReplicatedStorage.Common.SharedServices

local Root = {}
Root.__index = Root
Root.isServer = RunService:IsServer()
Root.isTesting = false
Root.Services = Services

function Root.new(replicatedContainer)
    local world = Matter.World.new()
    local state = {}

    local self = setmetatable({
        world = world;
        state = state;
        loop = nil;
        entityKey = nil;

        services = nil;
        status = Status.Uninitialized;

        _infosByUserId = {};
        _userIdsByName = {};
    }, Root)

    self.loop = Matter.Loop.new(self, state)
    self.services = Services.new(replicatedContainer)
    self.services:RegisterServicesIn(SharedServices)

    return self
end

function Root.newTest(systems, isServer)
    local self = Root.new(nil)
    self.isServer = isServer
    self.isTesting = true

    local _bindSignals, run = bindSignals.testBindSignals(self.isServer)
    self:Start(systems, _bindSignals)

    return self, run
end

function Root:_registerSystems(systems, signals)
    -- local systemsToSchedule = {}

    -- for _, system in systems do
    --     for name, callback in system.callbacks or {} do
    --         if signals[name] then
    --             table.insert(systemsToSchedule, {
    --                 system = callback;
    --                 event = name;
    --                 priority = system.priority;
    --             })
    --         elseif self.EventBus[name] then
    --             self.EventBus[name]:Connect(callback)
    --         else
    --             warn(("%q is not a valid event"):format(name))
    --         end
    --     end
    -- end

    self.loop:scheduleSystems(systems)
end

function Root:Start(systems: table | Instance, customBindSignals: callback?)
    assert(self.status == Status.Uninitialized, "Already started root")

    if not self.isTesting then
        CollectionService:GetInstanceRemovedSignal("MatterInstance"):Connect(function(instance)
            local id = instance:GetAttribute(self.entityKey)

            if id and self.world:contains(id) then
                self.world:despawn(id)
            end
        end)
    end

    self.entityKey = if self.isServer then "ServerEntityId" else "ClientEntityId"

    self:_registerSystems(if type(systems) == "table" then systems else getSystems(systems))

    self.loop:begin((customBindSignals or bindSignals.bindSignals)(function(nextFn, signalName)
        return function()
            if
                (self.isServer and signalName == "PreSimulation")
                or (not self.isServer and signalName == "PreRender")
            then
                local timestamp = workspace:GetServerTimeNow()
                self.state.currentTime, self.state.previousTime = timestamp, self.state.currentTime or timestamp
                self.state.deltaTime = if self.state.previousTime then timestamp - self.state.previousTime else 0
            end

            nextFn()
        end
    end))

    self.services.isServer = self.isServer

    return self.services:Start(self)
end

function Root:Bind(instance, newId)
	local id = instance:GetAttribute(self.entityKey)

	if id and id ~= newId and self.world:contains(id) then
		error(string.format(
			"%s is already bound to a Matter entity. " ..
			"Did you forget to despawn the old entity first?",
			instance:GetFullName(),
			2
		))
	end

	instance:SetAttribute(self.entityKey, id)
	CollectionService:AddTag(instance, "MatterInstance")

    return instance
end

function Root:QueueDespawn(id)
    self.world:insert(id, MatterComponents.QueuedForRemoval())
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

function Root:GetService(name)
    return self.services:GetService(name)
end

function Root:GetSingleton(name)
    return self.services:GetSingleton(name)
end

function Root:GetServerService(name)
    return self.services:GetServerService(name)
end

return Root.new()