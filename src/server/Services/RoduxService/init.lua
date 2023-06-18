local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IsDebug = RunService:IsStudio() and ReplicatedStorage:FindFirstChild("Configuration"):GetAttribute("IsDebug")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local t = require(ReplicatedStorage.Packages.t)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local Root = require(ReplicatedStorage.Common.Root)
local actions = RoduxFeatures.actions
local actionReplicators = require(script.actionReplicators)

local RoduxService = {
	Priority = math.huge,
	Client = {
		InitState = Root.Services.remoteEvent(),
		Request = Root.Services.remoteEvent(),
		ActionDispatched = Root.Services.remoteEvent(),
	},
	Name = "RoduxService",
}

local function initState()
	local place = ServerScriptService:FindFirstChild("Place")

	local defaultPermissions
	if place then
		defaultPermissions = place:FindFirstChild("DefaultPermissions")
		defaultPermissions = defaultPermissions and require(defaultPermissions)
	end

	return {
		users = {
			referees = defaultPermissions and table.clone(defaultPermissions.Referees) or {},
			admins = defaultPermissions and table.clone(defaultPermissions.Admins) or {},
		},
	}
end

local function serializeAction(action, state, userIds)
	local serializers = RoduxFeatures.serializers[action.type]

	local serializedAction
	if serializers and serializers.serialize then
		serializedAction = serializers.serialize(action, state)
	end

	local replicator = actionReplicators[action.type]
	if replicator and replicator.replicate then
		local actionMap = replicator.replicate(userIds, action, state, serializedAction)
		return actionMap, if serializers then serializers.id else nil
	end

	local actionMap = {}
	for _, userId in userIds do
		actionMap[userId] = serializedAction or action
	end

	return actionMap, if serializers then serializers.id else nil
end

local function getUserIds()
	local userIds = {}
	for _, player in Players:GetPlayers() do
		table.insert(userIds, player.UserId)
	end

	return userIds
end

function RoduxService:_makeServerMiddleware()
	return function(nextDispatch)
		return function(action)
			local meta = action.meta
			if meta and meta.realm == "client" then
				return
			end

			if not meta or meta.realm ~= "server" then
				local userIds = meta and meta.interestedUserIds or getUserIds()
				local actionMap, serializedType = serializeAction(action, self.Root.Store:getState(), userIds)

				for userId, userAction in actionMap do
					local player = Players:GetPlayerByUserId(userId)

					if player and player:GetAttribute("RoduxStateInitialized") then
						if type(userAction) == "table" and userAction.type then
							self.Client.ActionDispatched:FireClient(player, userAction)
						else
							self.Client.ActionDispatched:FireClient(player, userAction, serializedType)
						end
					end
				end
			end

			nextDispatch(action)
		end
	end
end

function RoduxService:OnPlayerAdded(player)
	local serialized = RoduxFeatures.reducer(self.Root.Store:getState(), RoduxFeatures.actions.serialize(player.UserId))
	self.Client.InitState:FireClient(player, serialized)
	player:SetAttribute("RoduxStateInitialized", true)

	self.Root.Store:dispatch(actions.userJoined(player.UserId, player.DisplayName, player.Name))
end

function RoduxService:OnPlayerRemoving(player)
	self.Root.Store:dispatch(actions.userLeft(player.UserId))
end

local function deserializeAction(serialized, actionType, state)
	local serializers = RoduxFeatures.serializers[actionType]
	if serializers then
		return serializers.deserialize(serialized, state)
	end

	return nil
end

local actionChecker = t.interface({
	type = t.string,
	payload = t.table,
})

function RoduxService:OnInit()
	local root = self.Root
	root.Store = Rodux.Store.new(RoduxFeatures.reducer, nil, {
		Rodux.thunkMiddleware,
		self:_makeServerMiddleware(),
		IsDebug and RoduxFeatures.middlewares.loggerMiddleware or nil,
	})

	root.StoreChanged = Signal.new()
	root.Store.changed:connect(function(...)
		root.StoreChanged:Fire(...)
	end)

	root.Store:dispatch(actions.merge(initState()))

	self.Client.Request:Connect(function(client, action, serializedType)
		if type(action) == "string" and serializedType then
			local ok, deserialized = pcall(deserializeAction, action, serializedType)
			if not ok then
				return
			end

			action = deserialized
		end

		if not actionChecker(action) then
			return
		end

		local replicators = actionReplicators[action.type]

		if replicators and replicators.request then
			local toDispatch = replicators.request(client.UserId, action)

			if toDispatch then
				root.Store:dispatch(toDispatch)
			end
		end
	end)
end

return RoduxService
