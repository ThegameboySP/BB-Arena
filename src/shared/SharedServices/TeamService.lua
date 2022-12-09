local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatterComponents = require(ReplicatedStorage.Common.MatterComponents)

local TeamService = {}

function TeamService:spawnTeam(team, ...)
	local id = self:getTeamFromName(team.name)
	if id then
		return self.Root.world:replace(id, team, ...)
	end

	return self.Root.world:spawn(team, ...)
end

function TeamService:getTeamFromName(name)
	for id, team in self.Root.world:query(MatterComponents.Team) do
		if team.name == name then
			return id
		end
	end

	return nil
end

function TeamService:getPlayersFromTeam(id)
	local players = {}

	for playerId, player in self.Root.world:query(MatterComponents.Player) do
		if player.teamId == id then
			table.insert(players, playerId)
		end
	end

	return players
end

return TeamService
