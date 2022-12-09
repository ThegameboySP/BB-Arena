local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local MatterComponents = require(ReplicatedStorage.Common.MatterComponents)

local function renderTeams(root, state)
	local teamsFolder = state.Teams or Teams

	for _, team in teamsFolder:GetChildren() do
		-- Assume this team has been placed through Studio.
		if not CollectionService:HasTag(team, "MatterInstance") then
			local id = root.world:spawn(MatterComponents.Team({
				name = team.Name,
				static = true,
				participating = CollectionService:HasTag(team, "ParticipatingTeam"),
				enableTools = CollectionService:HasTag(team, "ToolsEnabled"),
				color = team.TeamColor,
			}))

			root:Bind(team, id)
		end
	end

	local TeamService = root:GetService("TeamService")
	local id = TeamService:getTeamFromName("Gladiators")

	if state.mapSupportsGladiators and (state.gamemodeRequiresGladiators or state.adminRequestsGladiators) then
		if not id then
			id = TeamService:spawnTeam(MatterComponents.Team({
				name = "Gladiators",
				color = BrickColor.Red(),
				participating = true,
				enableTools = true,
			}))
		end
	elseif id then
		root:QueueDespawn(id)
	end

	for teamId, teamRecord in root.world:queryChanged(MatterComponents.Team) do
		if teamRecord.old then
			local oldTeam = teamsFolder:FindFirstChild(teamRecord.old.name)
			if oldTeam then
				for _, playerId in TeamService:getPlayersFromTeam(teamId) do
					local player = root.world:get(playerId, MatterComponents.Player)
					if player.player then
						player.player.Team = Teams.Spectators
					end
				end

				oldTeam.Parent = nil
			end
		end

		if teamRecord.new and not teamRecord.new.static then
			local team = root:Bind(Instance.new("Team"), teamId)
			team.Name = teamRecord.new.name
			team.TeamColor = teamRecord.new.color

			-- TODO: handle team attributes entirely through Matter teams
			if teamRecord.new.enableTools then
				CollectionService:AddTag(team, "ToolsEnabled")
			end

			if teamRecord.new.participating then
				CollectionService:AddTag(team, "ParticipatingTeam")
			end

			team.Parent = teamsFolder

			for _, playerId in TeamService:getPlayersFromTeam(teamId) do
				local player = root.world:get(playerId, MatterComponents.Player)
				if player.player then
					player.player.Team = team
				end
			end
		else
			for _, playerId in TeamService:getPlayersFromTeam(teamId) do
				local player = root.world:get(playerId, MatterComponents.Player)
				if player.player then
					player.player.Team = Teams.Spectators
				end
			end
		end
	end
end

return {
	event = "PreSimulation",
	priority = GameEnum.SystemPriorities.CoreAfter,
	system = renderTeams,
}
