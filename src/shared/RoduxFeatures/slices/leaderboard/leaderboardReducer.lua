local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Dictionary = Llama.Dictionary

local RoduxUtils = require(script.Parent.Parent.Parent.RoduxUtils)

return Rodux.createReducer({
	lastFetched = 0,
	fetchFailed = false,
	hasFetched = false,
	users = {},
	placeByUserId = {},
}, {
	rodux_serialize = function(state)
		local serialized = table.clone(state)
		serialized.users = RoduxUtils.numberIndicesToString(state.users)
		serialized.placeByUserId = RoduxUtils.numberIndicesToString(state.placeByUserId)

		return serialized
	end,
	rodux_deserialize = function(state, action)
		local serialized = action.payload.serialized.leaderboard
		local patch = {}

		patch.users = RoduxUtils.stringIndicesToNumber(serialized.users)
		patch.placeByUserId = RoduxUtils.stringIndicesToNumber(serialized.placeByUserId)

		return Dictionary.merge(state, patch)
	end,
	leaderboard_fetched = function(state, action)
		local placeByUserId = {}
		for place, entry in action.payload.leaderboard do
			placeByUserId[entry.userId] = place
		end

		return Dictionary.merge(state, {
			lastFetched = Workspace:GetServerTimeNow(),
			fetchFailed = false,
			hasFetched = true,
			users = action.payload.leaderboard,
			placeByUserId = placeByUserId,
		})
	end,
	leaderboard_fetchFailed = function(state)
		return Dictionary.merge(state, {
			fetchFailed = true,
		})
	end,
})
