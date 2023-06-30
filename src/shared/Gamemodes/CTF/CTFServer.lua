local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Components = require(ReplicatedStorage.Common.Components)
local RichText = require(ReplicatedStorage.Common.Utils.RichText)

local CTFServer = {}
CTFServer.__index = CTFServer
CTFServer.UpdateEvent = RunService.Heartbeat

local trowelOverlapParams = OverlapParams.new()
trowelOverlapParams.FilterType = Enum.RaycastFilterType.Whitelist

function CTFServer.new(service, binder)
	return setmetatable({
		service = service,
		binder = binder,
		scores = {},
	}, CTFServer)
end

function CTFServer:Destroy()
	self.destruct()
end

function CTFServer:OnScoresSet(teamScores)
	local delta = {}
	for team, score in pairs(teamScores) do
		delta[team.Name .. "Score"] = score
		self.scores[team] = score
	end

	self.binder:SetState(delta)
end

function CTFServer:OnConfigChanged(config)
	self.config = config
	self.binder:SetState(config)
end

function CTFServer:OnInit(config, teams)
	self:OnConfigChanged(config)
	self.teams = teams

	local stolenRemote = self.service:GetRemoteEvent("CTF_Stolen")
	local capturedRemote = self.service:GetRemoteEvent("CTF_Captured")
	local recoveredRemote = self.service:GetRemoteEvent("CTF_Recovered")

	for _, team in ipairs(teams) do
		self:addPointToTeam(team, 0)
	end

	local flagDistance = {}
	local carryingPlayers = {}
	local flagPositions = {}

	local componentManager = self.service:GetManager()
	local flags = componentManager:GetComponents(Components.S_CTF_Flag)

	for _, flag in flags do
		flag.Captured:Connect(function(player)
			capturedRemote:FireAllClients({
				flag = flag.Instance,
				player = player,
				team = flag.State.Team,
				distanceTraveled = flagDistance[player].distance or 0,
			})

			flagDistance[player] = nil

			self:addPointToTeam(player.Team, 1)
			self.service.StatService:IncrementStat(player.UserId, "CTF_captures", 1)
		end)

		flag.PickedUp:Connect(function(player)
			carryingPlayers[player] = true

			local data = flagDistance[player]
			flagDistance[player] = {
				distance = (data and data.distance) or 0,
				lastPosition = player.Character.PrimaryPart.Position,
			}
		end)

		flag.Dropped:Connect(function(player)
			carryingPlayers[player] = nil
		end)

		flag.Recovered:Connect(function(player)
			local enemyStands = {}
			local thisFlagStand

			for _, flagStand in componentManager:GetComponents(Components.S_CTF_FlagStand) do
				if flagStand.State.Flag == flag.Instance then
					thisFlagStand = flagStand
				end

				if flagStand.State.Team ~= flag.State.Team then
					table.insert(enemyStands, flagStand.Instance)
				end
			end

			local standPosition = thisFlagStand.Instance.Position
			table.sort(enemyStands, function(a, b)
				return (a.Position - standPosition).Magnitude > (b.Position - standPosition).Magnitude
			end)

			local closestEnemyStand = enemyStands[1]
			local lastFlagPosition = flagPositions[flag]

			print("flag position:", lastFlagPosition, "closest enemy stand:", closestEnemyStand.Position)

			local captureDist = (closestEnemyStand.Position - lastFlagPosition).Magnitude
			local standsDist = (standPosition - closestEnemyStand.Position).Magnitude
			local defensiveClutch = (1 - math.min((captureDist / standsDist), 1)) * 100

			recoveredRemote:FireAllClients({
				flag = flag.Instance,
				player = player,
				defensiveClutch = defensiveClutch,
			})
		end)

		flag.Docked:Connect(function(player)
			carryingPlayers[player] = nil
		end)

		flag.Stolen:Connect(function(player)
			stolenRemote:FireAllClients({
				flag = flag.Instance,
				player = player,
				team = flag.State.Team,
			})
		end)
	end

	local updateConnection = self.UpdateEvent:Connect(function()
		-- Prevent players from troweling the flag to prevent capture.
		for _, flag in flags do
			trowelOverlapParams.FilterDescendantsInstances = CollectionService:GetTagged("TrowelWallBrick")
			if flag.State.State == "Docked" then
				for _, part in Workspace:GetPartBoundsInRadius(flag.Instance.Position, 3, trowelOverlapParams) do
					part.Parent = nil
				end
			end
		end

		for _, flag in flags do
			flagPositions[flag] = flag.Instance.Position
		end

		for player, data in flagDistance do
			if not player.Parent then
				flagDistance[player] = nil
				continue
			end

			local character = player.Character

			if character and character.PrimaryPart then
				local currentPosition = character.PrimaryPart.Position
				local dist = (data.lastPosition - currentPosition).Magnitude

				data.distance += dist
				data.lastPosition = currentPosition
			end
		end

		for team, score in pairs(self.scores) do
			if score >= self.config.maxScore then
				self:finish(team)
				break
			end
		end
	end)

	self.destruct = function()
		updateConnection:Disconnect()
	end
end

function CTFServer:addPointToTeam(team, amount)
	local score = self.scores[team] or 0
	self.binder:SetState({ [team.Name .. "Score"] = score + amount })
	self.scores[team] = score + amount
end

local function formatWonGame(winningTeam, teamToScore)
	local scores = {}
	for team, score in pairs(teamToScore) do
		table.insert(scores, { team = team, score = score })
	end

	table.sort(scores, function(a, b)
		return a.score > b.score
	end)

	local scoreStrings = {}
	for _, data in ipairs(scores) do
		table.insert(scoreStrings, string.format("%s team: %d", data.team.Name, data.score))
	end

	return RichText.color(
		string.format("The %s team has won the game!\n", winningTeam.Name),
		winningTeam.TeamColor.Color
	) .. RichText.color(table.concat(scoreStrings, "\n"), Color3.new(1, 1, 1))
end

function CTFServer:finish(winningTeam)
	self.service:AnnounceEvent(formatWonGame(winningTeam, self.scores), {
		stayOpen = true,
	})

	local losingPlayers = {}
	for _, team in self.teams do
		if team ~= winningTeam then
			for _, player in team:GetPlayers() do
				table.insert(losingPlayers, player)
			end
		end
	end

	self.service:StopGamemode(winningTeam:GetPlayers(), losingPlayers)
end

return CTFServer
