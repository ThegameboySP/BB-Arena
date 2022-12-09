local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
	stopOnMapChange = false,
	minTeams = 2,
	hasMapProps = false,

	friendlyName = "Scrimmage",
	nameId = "Scrimmage",
	config = {
		maxScore = t.numberMin(1),
		wb2 = t.boolean,
		tiesCount = t.boolean,
	},

	cmdrConfig = {
		scoresSet = CmdrUtils.fightingTeamTo(CmdrUtils.constrainedInteger(0, math.huge), {
			Name = "set team scores",
			Description = "example: Red=0,Blue=0",
		}),
		maxScore = {
			Type = CmdrUtils.constrainedInteger(1, math.huge),
			Name = "max score",
			Description = "The score a team needs to achieve to win the game.",
		},
		wb2 = {
			Type = "boolean",
			Name = "win by two",
			Description = "Whether a team needs to have at least 2 more rounds won to win the game.",
			Optional = true,
			Default = false,
		},
		tiesCount = {
			Type = "boolean",
			Name = "ties count",
			Description = "Whether all teams dying in a round should count as a win for all teams.",
			Optional = true,
			Default = false,
		},
	},

	stats = {},
}
