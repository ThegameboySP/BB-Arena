local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
    stopOnMapChange = true;
	minTeams = 2;

	friendlyName = "Control Points";
	nameId = "ControlPoints";
	config = {
		maxScore = t.numberMin(1);
	};

	cmdrConfig = {
		scoresSet = CmdrUtils.fightingTeamTo(CmdrUtils.constrainedInteger(0, math.huge), {
            Name = "set team scores";
            Description = "example: Red=0,Blue=0";
        });
		maxScore = {
			Type = CmdrUtils.constrainedInteger(1, math.huge);
			Name = "max score";
			Description = "The score a team needs to achieve to win the game.";
		}
	};

	stats = {
		CP_secondsDefending = {
			default = 0;
		};
		CP_secondsAttacking = {
			default = 0;
		};
		CP_pointsCaptures = {
			default = 0;
			friendlyName = "Captures";
			show = true;
		}
	};
}