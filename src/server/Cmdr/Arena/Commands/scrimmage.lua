local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Scrimmage = require(ReplicatedStorage.Common.Gamemodes.Scrimmage)

return {
	Name = "scrimmage";
	Aliases = {"scrim", "duelmode"};
	Description = "Starts Scrimmage, stopping the current gamemode.";
	Group = "Admin";
	Args = {
		Scrimmage.definition.cmdrConfig.maxScore;
        Scrimmage.definition.cmdrConfig.wb2;
        Scrimmage.definition.cmdrConfig.tiesCount;
	};

    Run = function(context, maxScore, wb2, tiesCount)
        return context.Cmdr.Dispatcher:EvaluateAndRun("__startGamemode Scrimmage", context.Executor, {
            Data = {
                config = {
                    maxScore = maxScore;
                    wb2 = wb2;
                    tiesCount = tiesCount;
                }
            }
        })
    end;
}