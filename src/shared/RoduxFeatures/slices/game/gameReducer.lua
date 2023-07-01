local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local Dictionary = Llama.Dictionary

return Rodux.createReducer({
	mapInfo = {},
	anonymousFighters = false,
	gamemodeId = nil,
	mapId = nil,
}, {
	rodux_deserialize = function(_, action)
		return action.payload.serialized.game
	end,
	game_gamemodeStarted = function(state, action)
		return Dictionary.merge(state, {
			gamemodeId = action.payload.gamemodeId,
		})
	end,
	game_gamemodeEnded = function(state)
		return Dictionary.merge(state, {
			gamemodeId = Llama.None,
		})
	end,
	game_mapChanged = function(state, action)
		return Dictionary.merge(state, {
			mapId = action.payload.mapId,
		})
	end,
	game_setMapInfo = function(state, action)
		return Dictionary.merge(state, {
			mapInfo = action.payload.mapInfo,
		})
	end,
	game_setSpecificMapInfo = function(state, action)
		local mapName = action.payload.mapName

		local merged = Dictionary.merge(state.mapInfo[mapName], action.payload.mapInfo)

		return Dictionary.merge(state, { mapInfo = Dictionary.merge(state.mapInfo, { [mapName] = merged }) })
	end,
	game_setAnonymousFighters = function(state, action)
		return Dictionary.merge(state, {
			anonymousFighters = action.payload.enabled,
		})
	end,
})
