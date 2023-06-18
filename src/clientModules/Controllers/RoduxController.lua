local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local IsDebug = RunService:IsStudio() and ReplicatedStorage:FindFirstChild("Configuration"):GetAttribute("IsDebug")
local LocalPlayer = Players.LocalPlayer

local RoduxController = {
	Priority = math.huge,
	Name = "RoduxController",
}

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

function RoduxController:_makeClientMiddleware(requestRemote)
	return function(nextDispatch)
		return function(action)
			local meta = action.meta
			if meta and meta.realm == "server" then
				return
			end

			if meta and meta.serverInterested and not meta.dispatchedByServer then
				requestRemote:FireServer(serializeAction(action, self.Root.Store:getState()))

				if meta.interestedUserIds and not table.find(meta.interestedUserIds, LocalPlayer.UserId) then
					return
				end
			end

			nextDispatch(action)
		end
	end
end

function RoduxController:OnInit()
	self.RoduxService = self.Root:GetServerService("RoduxService")

	local thread = coroutine.running()
	self.RoduxService.InitState:Connect(function(state)
		local deserialized = RoduxFeatures.reducer({}, RoduxFeatures.actions.deserialize(state))

		self.Root.Store = Rodux.Store.new(RoduxFeatures.reducer, deserialized, {
			Rodux.thunkMiddleware,
			self:_makeClientMiddleware(self.RoduxService.Request),
			IsDebug and RoduxFeatures.middlewares.loggerMiddleware or nil,
		})

		self.Root.StoreChanged = Signal.new()
		self.Root.Store.changed:connect(function(...)
			self.Root.StoreChanged:Fire(...)
		end)

		if coroutine.status(thread) == "suspended" then
			task.spawn(thread)
		end
	end)

	if not self.Root.Store then
		warn("[RoduxController]", "Yielding until InitState is received")
		coroutine.yield()
	end

	self.RoduxService.ActionDispatched:Connect(function(action, serializedType)
		local resolvedAction = action
		if serializedType then
			resolvedAction = deserializeAction(action, serializedType, self.Root.Store:getState())
		end

		resolvedAction.meta = resolvedAction.meta or {}
		resolvedAction.meta.dispatchedByServer = true

		self.Root.Store:dispatch(resolvedAction)
	end)
end

return RoduxController
