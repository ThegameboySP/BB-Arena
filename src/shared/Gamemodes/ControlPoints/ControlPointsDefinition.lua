local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
    stopOnMapChange = true;
	groupName = "ControlPoints";
	config = t.strictInterface({
		maxScore = t.numberMin(1);
	});
	supportsGamemode = function(map)
		if map:FindFirstChild("ControlPoints") == nil then
			return false, "Map does not support Control Points"
		end

		if #CollectionService:GetTagged("FightingTeam") == 1 then
			return false, "Control Points needs more than 1 fighting team to work"
		end

		return true
	end;

	cmdrCommandName = "startControlPoints";
	cmdrEvents = {
		scoresSet = CmdrUtils.fightingTeamTo(CmdrUtils.constrainedInteger(0, math.huge), {
            Name = "set team scores";
            Description = "example: Red=0,Blue=0";
        });
		maxScoreSet = {
			Type = CmdrUtils.constrainedInteger(1, math.huge);
			Name = "max score";
			Description = "The score a team needs to achieve to win the game.";
		}
	};

	stats = {
		secondsDefending = {
			default = 0;
		};
		secondsAttacking = {
			default = 0;
		};
		pointsCaptured = {
			default = 0;
		}
	};
}