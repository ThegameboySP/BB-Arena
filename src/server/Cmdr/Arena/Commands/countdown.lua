local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
	Name = "countdown",
	Aliases = { "cd" },
	Description = "Counts down from the seconds you give.",
	Group = "Admin",
	Args = {
		{
			Type = CmdrUtils.constrainedInteger(1, 5),
			Name = "seconds",
			Description = "The seconds to count down",
			Optional = true,
			Default = 3,
		},
	},
}
