local statsActions = require(script.Parent.statsActions)

return {
	stats_increment = {
		serialize = function(action, state)
			local payload = action.payload
			local id = state.stats.registeredStats[payload.name].id
			return string.pack("dBd", payload.userId, id, payload.amount)
		end,
		deserialize = function(serialized, state)
			local userId, id, amount = string.unpack("dBd", serialized)
			local name = state.stats.registeredStats[id].name
			return statsActions.incrementStat(userId, name, amount)
		end,
	},
	stats_initializeUser = {
		serialize = function(action, state)
			local payload = action.payload

			local settings = {}

			local serializedStats = {}
			for name, value in payload.stats do
				local id = string.char(state.stats.registeredStats[name].id)
				serializedStats[id] = value
			end

			return { payload.userId, serializedStats }
		end,
		deserialize = function(serialized, state)
			local deserializedStats = {}

			for id, value in serialized[2] do
				local numberId = string.byte(id)
				local name = state.stats.registeredStats[numberId].name
				deserializedStats[name] = value
			end

			return statsActions.initializeUserStats(serialized[1], deserializedStats)
		end,
	},
}
