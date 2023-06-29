local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
	Name = "setLeaderboardData",
	Aliases = {},
	Description = "Sets leaderboard data. USE WITH CAUTION.",
	Group = "SuperOwner",
	Args = {
		{
			Type = "playerId",
			Name = "player",
		},
		{
			Type = CmdrUtils.enum("LeaderboardKey", { "KOs", "WOs" }),
			Name = "Leaderboard key",
			Description = "The leaderboard key to set.",
		},
		{
			Type = CmdrUtils.constrainedInteger(0, 99_999),
			Name = "number",
			Description = "The number to set the key to.",
		},
	},
}
