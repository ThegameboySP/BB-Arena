local leaderboardActions = {}

function leaderboardActions.leaderboardFetched(leaderboard)
	return {
		type = "leaderboard_fetched",
		payload = {
			leaderboard = leaderboard,
		},
	}
end

function leaderboardActions.leaderboardFetchFailed()
	return {
		type = "leaderboard_fetchFailed",
		payload = {},
	}
end

return leaderboardActions
