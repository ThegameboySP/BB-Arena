local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local S_ControlPoint = require(ReplicatedStorage.Common.Components).S_ControlPoint
local RichText = require(ReplicatedStorage.Common.Utils.RichText)

local strings = {
	wonGame = "The %s team has won the game!",
	centerCaptured = "%s just captured the center point!",
	pointCaptured = "%s just captured point %d!",
}

local ControlPointsServer = {}
ControlPointsServer.__index = ControlPointsServer
ControlPointsServer.UpdateEvent = RunService.Heartbeat

function ControlPointsServer.new(service, binder)
	return setmetatable({
		service = service,
		binder = binder,
		scores = {},
	}, ControlPointsServer)
end

function ControlPointsServer:Destroy()
	self.destruct()
end

function ControlPointsServer:OnScoresSet(teamScores)
	local delta = {}
	for team, score in pairs(teamScores) do
		delta[team.Name .. "Score"] = score
		self.scores[team] = score
	end

	self.binder:SetState(delta)
end

function ControlPointsServer:OnConfigChanged(config)
	self.config = config
	self.binder:SetState(config)
end

function ControlPointsServer:OnInit(config, fightingTeams)
	self:OnConfigChanged(config)

	local replicatedRoot = Instance.new("Folder")
	replicatedRoot.Name = "ControlPointsValues"

	local healedEvent = Instance.new("RemoteEvent")
	healedEvent.Name = "Healed"
	healedEvent.Parent = replicatedRoot
	replicatedRoot.Parent = ReplicatedStorage

	self.teamToRate = {}

	for _, team in pairs(fightingTeams) do
		self.teamToRate[team] = 0
		self.scores[team] = 0
	end

	self.onCaptured = function(cp)
		local team = cp.State.CapturedBy
		local increase = cp.Config.IsCenter and 2 or 1

		self.teamToRate[team] += increase

		for _, player in pairs(cp:GetPlayersInside()) do
			local char = player.Character
			if char == nil then
				continue
			end
			local hum = char:FindFirstChild("Humanoid")
			if hum == nil then
				continue
			end

			hum.Health = hum.MaxHealth
			healedEvent:FireAllClients(char)

			self.service.StatService:IncrementStat(player.UserId, "CP_pointsCaptures", 1)
		end

		if cp.Config.IsCenter then
			self.service:SayEvent(strings.centerCaptured:format(team.Name))
		else
			self.service:SayEvent(strings.pointCaptured:format(team.Name, cp.Config.Order))
		end

		return function()
			self.teamToRate[team] -= increase
		end
	end

	self.disconnectControlPoints = self:_connectOnCaptured()

	local con = self.UpdateEvent:Connect(function(dt)
		for _, cp in pairs(self.service:GetManager():GetComponents(S_ControlPoint)) do
			local capturedTeam = cp.State.CapturedBy

			local players = cp:GetPlayersInside()

			local defendingPlayers = {}
			local attackingPlayers = {}

			for _, player in pairs(players) do
				if player.Team == capturedTeam then
					table.insert(defendingPlayers, player)
				else
					table.insert(attackingPlayers, player)
				end
			end

			if defendingPlayers[1] and attackingPlayers[1] then
				for _, player in pairs(defendingPlayers) do
					self.service.StatService:IncrementStat(player.UserId, "CP_secondsDefending", dt)
				end
			else
				for _, player in pairs(attackingPlayers) do
					self.service.StatService:IncrementStat(player.UserId, "CP_secondsAttacking", dt)
				end
			end
		end

		local delta = {}
		local highestScore = 0
		local highestTeams = {}

		local lowestTimeInSecondsToWin = math.huge
		local lowestTimeInSecondsToWinTeam

		local isDirty = false

		for team, rate in pairs(self.teamToRate) do
			local newScore = (self.scores[team] or 0) + rate * dt

			if math.floor(self.scores[team]) ~= math.floor(newScore) then
				isDirty = true
			end

			delta[team.Name .. "Score"] = math.floor(newScore)
			self.scores[team] = newScore

			local timeInSecondsToWin = (self.config.maxScore - newScore) / rate
			if lowestTimeInSecondsToWin > timeInSecondsToWin then
				lowestTimeInSecondsToWin = timeInSecondsToWin
				lowestTimeInSecondsToWinTeam = team
			end

			if math.floor(newScore) > math.floor(highestScore) then
				highestScore = newScore
				highestTeams = { team }
			elseif math.floor(newScore) == math.floor(highestScore) then
				table.insert(highestTeams, team)
			end
		end

		if #highestTeams == 1 and highestScore >= self.config.maxScore then
			self:finish(highestTeams[1])
			return
		end

		if lowestTimeInSecondsToWinTeam then
			delta.WinningName = lowestTimeInSecondsToWinTeam.Name
		end

		if isDirty then
			self.binder:SetState(delta)
		end
	end)

	self.destruct = function()
		self.disconnectControlPoints()
		con:Disconnect()
		replicatedRoot:Destroy()
	end
end

function ControlPointsServer:OnMapChanged(oldTeamToNewTeam)
	-- local delta = {}

	-- for oldTeam, newTeam in oldTeamToNewTeam do
	--     self.scores[newTeam] = self.scores[oldTeam] or 0
	--     self.scores[oldTeam] = nil

	--     local oldValue = delta[oldTeam.Name .. "Score"]

	--     -- Annoyingly, old and new team names can overlap between iterations.
	--     if type(oldValue) ~= "number" then
	--         delta[oldTeam.Name .. "Score"] = Llama.None
	--     end

	--     delta[newTeam.Name .. "Score"] = math.floor(self.scores[newTeam])

	--     self.teamToRate[newTeam] = 0
	--     self.teamToRate[oldTeam] = nil
	-- end

	-- self.binder:SetState(delta)

	-- self.disconnectControlPoints()
	-- self.disconnectControlPoints = self:_connectOnCaptured()
end

function ControlPointsServer:_connectOnCaptured()
	local cons = {}

	for _, cp in pairs(self.service:GetManager():GetComponents(S_ControlPoint)) do
		local destruct
		table.insert(
			cons,
			cp.Captured:Connect(function()
				destruct = self.onCaptured(cp)
			end)
		)

		table.insert(
			cons,
			cp.Uncaptured:Connect(function()
				if destruct then
					destruct()
				end
			end)
		)
	end

	return function()
		for _, con in pairs(cons) do
			con:Disconnect()
		end
	end
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

	return
		RichText.color(
		string.format("The %s team has won the game!\n", winningTeam.Name),
		winningTeam.TeamColor.Color
	) .. RichText.color(table.concat(scoreStrings, "\n"), Color3.new(1, 1, 1))
end

function ControlPointsServer:finish(winningTeam)
	self.service:AnnounceEvent(formatWonGame(winningTeam, self.scores), {
		stayOpen = true,
	})

	self.service:StopGamemode(true)
end

return ControlPointsServer
