local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlPoints = require(ReplicatedStorage.Common.Gamemodes.ControlPoints)

return {
	Name = "controlPoints",
	Aliases = { "cp" },
	Description = "Starts Control Points, stopping the current gamemode.",
	Group = "Admin",
	Args = {
		ControlPoints.definition.cmdrConfig.maxScore or error("No max score"),
	},

	Run = function(context, maxScore)
		return context.Cmdr.Dispatcher:EvaluateAndRun("__startGamemode ControlPoints", context.Executor, {
			Data = {
				config = {
					maxScore = maxScore,
				},
			},
		})
	end,
}
