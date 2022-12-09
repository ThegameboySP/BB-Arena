local gameActions = {}

function gameActions.gamemodeStarted(gamemodeId)
	return {
		type = "game_gamemodeStarted",
		payload = {
			gamemodeId = gamemodeId,
		},
	}
end

function gameActions.gamemodeEnded(gamemodeId)
	return {
		type = "game_gamemodeEnded",
		payload = {
			gamemodeId = gamemodeId,
		},
	}
end

function gameActions.mapChanged(mapId)
	return {
		type = "game_mapChanged",
		payload = {
			mapId = mapId,
		},
	}
end

function gameActions.setMapInfo(mapInfo)
	return {
		type = "game_setMapInfo",
		payload = {
			mapInfo = mapInfo,
		},
	}
end

function gameActions.playerDied(userId, killerId, cause, weapon, distance)
	return {
		type = "game_playerDied",
		payload = {
			userId = userId,
			killerId = killerId,
			deathCause = cause,
			weapon = weapon,
			distance = distance,
		},
	}
end

function gameActions.setAnonymousFighters(enabled)
	return function(store)
		if store:getState().game.anonymousFighters ~= enabled then
			store:dispatch({
				type = "game_setAnonymousFighters",
				payload = {
					enabled = enabled,
				},
			})
		end
	end
end

return gameActions
