local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CTF = require(ReplicatedStorage.Common.Gamemodes.CTF)

return {
	Name = "captureTheFlag";
	Aliases = {"ctf"};
	Description = "Starts Capture the Flag, stopping the current gamemode.";
	Group = "Admin";
	Args = {
		CTF.definition.cmdrConfig.maxScore or error("No max score");
	};

    Run = function(context, maxScore)
        return context.Cmdr.Dispatcher:EvaluateAndRun("__startGamemode CTF", context.Executor, {
            Data = {
                config = {
                    maxScore = maxScore;
                }
            }
        })
    end;
}