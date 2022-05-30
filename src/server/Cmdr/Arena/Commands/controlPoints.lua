local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
	Name = "controlPoints";
	Aliases = {"cp"};
	Description = "Starts Control Points, stopping the current gamemode.";
	Group = "Admin";
	Args = {
		{
			Type = CmdrUtils.constrainedInteger(1, math.huge);
			Name = "maxScore";
			Description = "The score a team needs to achieve to win the game.";
		}
	};

    Run = function(context, maxScore)
        return context.Cmdr.Dispatcher:EvaluateAndRun("__startGamemode ControlPoints", context.Executor, {
            Data = {
                config = {
                    maxScore = maxScore;
                }
            }
        })
    end;
}