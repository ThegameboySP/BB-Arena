local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
	Name = "forceAdmin",
	Description = "Forces an admin set. Debugging only.",
	Group = "Studio",
	Args = {
		{
			Type = "players",
			Name = "players",
		},
		{
			Type = CmdrUtils.constrainedInteger(0, 2),
			Name = "admin rank",
		},
	},
}
