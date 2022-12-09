local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local IsDebug = RunService:IsStudio() and ReplicatedStorage:FindFirstChild("Configuration"):GetAttribute("IsDebug")
local LocalPlayer = Players.LocalPlayer

local function deserializeAction(serialized, actionType, state)
	local serializers = RoduxFeatures.serializers[actionType]
	if serializers then
		return serializers.deserialize(serialized, state)
	end

	error(("No deserializer for action %q"):format(string.byte(actionType)))
end

local function serializeAction(action, state)
	local serializers = RoduxFeatures.serializers[action.type]

	if serializers and serializers.serialize then
		return serializers.serialize(action, state), serializers.id
	end

	return action
end

local function makeClientMiddleware(requestRemote, root)
	return function(nextDispatch)
		return function(action)
			local meta = action.meta
			if meta and meta.realm == "server" then
				return
			end

			if meta and meta.serverInterested and not meta.dispatchedByServer then
				requestRemote:FireServer(serializeAction(action, root.Store:getState()))

				if meta.interestedUserIds and not table.find(meta.interestedUserIds, LocalPlayer.UserId) then
					return
				end
			end

			nextDispatch(action)
		end
	end
end

local function roduxClient(root)
	local initStateRemote = root:getRemoteEvent("Rodux_InitState")
	local requestRemote = root:getRemoteEvent("Rodux_Request")
	local actionDispatchedRemote = root:getRemoteEvent("Rodux_ActionDispatched")

	initStateRemote.OnClientEvent:Connect(function(state)
		local deserialized = RoduxFeatures.reducer({}, RoduxFeatures.actions.deserialize(state))

		root.Store = Rodux.Store.new(
			RoduxFeatures.reducer,
			deserialized,
			{
				Rodux.thunkMiddleware,
				makeClientMiddleware(requestRemote, root),
				IsDebug and RoduxFeatures.middlewares.loggerMiddleware or nil,
			}
		)

		root.StoreChanged = Signal.new()
		root.Store.changed:connect(function(...)
			root.StoreChanged:Fire(...)
		end)
	end)

	actionDispatchedRemote.OnClientEvent:Connect(function(action, serializedType)
		local resolvedAction = action
		if serializedType then
			resolvedAction = deserializeAction(action, serializedType, root.Store:getState())
		end

		resolvedAction.meta = resolvedAction.meta or {}
		resolvedAction.meta.dispatchedByServer = true

		root.Store:dispatch(resolvedAction)
	end)
end

return roduxClient
