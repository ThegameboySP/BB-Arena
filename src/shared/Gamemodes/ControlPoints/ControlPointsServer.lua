local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local S_ControlPoint = require(ReplicatedStorage.Common.Components.S_ControlPoint)
local strings = {
    wonGame = "The %s team has won the game!";
    centerCaptured = "%s just captured the center point!";
    pointCaptured = "%s just captured point %d!";
}

local ControlPointsServer = {}
ControlPointsServer.__index = ControlPointsServer
ControlPointsServer.UpdateEvent = RunService.Heartbeat

function ControlPointsServer.new(service, binder)
    return setmetatable({
        service = service;
        binder = binder;
        scores = {};
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

function ControlPointsServer:OnMaxScoreSet(maxScore)
    self.config.maxScore = maxScore

    self.binder:SetState({
        maxScore = maxScore;
    })
end

function ControlPointsServer:OnInit(config, fightingTeams)
    self.config = config
    self.binder:SetState({
        maxScore = config.maxScore
    })

    local replicatedRoot = Instance.new("Folder")
    replicatedRoot.Name = "ControlPointsValues"
    for _, team in pairs(fightingTeams) do
        replicatedRoot:SetAttribute(team.Name, 0)
    end

    local healedEvent = Instance.new("RemoteEvent")
    healedEvent.Name = "Healed"
    healedEvent.Parent = replicatedRoot
    replicatedRoot.Parent = ReplicatedStorage

    local teamToRate = {}
    for _, team in pairs(fightingTeams) do
        teamToRate[team] = 0
    end

    local undo = self:_onPointCaptured(function(cp)
        local team = cp.State.CapturedBy
        local increase = cp.Config.IsCenter and 2 or 1

        teamToRate[team] += increase

        for _, player in pairs(cp:GetPlayersInside()) do
            local char = player.Character
            if char == nil then continue end
            local hum = char:FindFirstChild("Humanoid")
            if hum == nil then continue end

            hum.Health = hum.MaxHealth
            healedEvent:FireAllClients(char)
        end

        if cp.Config.IsCenter then
            self.service:SayEvent(strings.centerCaptured:format(team.Name))
        else
            self.service:SayEvent(strings.pointCaptured:format(team.Name, cp.Config.Order))
        end

        return function()
            teamToRate[team] -= increase
        end
    end)

    local con = self.UpdateEvent:Connect(function(dt)
        local delta = {}
        local highestScore = 0
        local highestTeams = {}

        local lowestTimeInSecondsToWin = math.huge
        local lowestTimeInSecondsToWinTeam

        for team, rate in pairs(teamToRate) do
            local newScore = (self.scores[team] or 0) + rate * dt
            delta[team.Name .. "Score"] = math.floor(newScore)
            self.scores[team] = newScore

            local timeInSecondsToWin = (self.config.maxScore - newScore) / rate
            if lowestTimeInSecondsToWin > timeInSecondsToWin then
                lowestTimeInSecondsToWin = timeInSecondsToWin
                lowestTimeInSecondsToWinTeam = team
            end

            if math.floor(newScore) > math.floor(highestScore) then
                highestScore = newScore
                highestTeams = {team}
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

        self.binder:SetState(delta)
    end)

    self.destruct = function()
        undo()
        con:Disconnect()
        replicatedRoot:Destroy()
    end
end

function ControlPointsServer:_onPointCaptured(onCaptured)
    local cons = {}

    for _, cp in pairs(self.service:GetManager():GetComponents(S_ControlPoint)) do
        local destruct
        table.insert(cons, cp.Captured:Connect(function()
            destruct = onCaptured(cp)
        end))

        table.insert(cons, cp.Uncaptured:Connect(function()
            if destruct then
                destruct()
            end
        end))
    end

    return function()
        for _, con in pairs(cons) do
            con:Disconnect()
        end
    end
end

function ControlPointsServer:finish(winningTeam)
    self.service:AnnounceEvent(strings.wonGame:format(winningTeam.Name))
	self.service:StopGamemode()
end

return ControlPointsServer