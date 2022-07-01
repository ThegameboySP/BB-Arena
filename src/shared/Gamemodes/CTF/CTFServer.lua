local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.Common.Components)

local CTFServer = {}
CTFServer.__index = CTFServer
CTFServer.UpdateEvent = RunService.Heartbeat

function CTFServer.new(service, binder)
    return setmetatable({
        service = service;
        binder = binder;
        scores = {};
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

    local replicatedRoot = Instance.new("Folder")
    replicatedRoot.Name = "CTFValues"

    local stolenRemote = Instance.new("RemoteEvent")
    stolenRemote.Name = "Stolen"
    stolenRemote.Parent = replicatedRoot

    local capturedRemote = Instance.new("RemoteEvent")
    capturedRemote.Name = "Captured"
    capturedRemote.Parent = replicatedRoot

    replicatedRoot.Parent = ReplicatedStorage

    for _, team in ipairs(teams) do
        self:addPointToTeam(team, 0)
    end

    for _, flag in ipairs(self.service:GetManager():GetComponents(Components.S_CTF_Flag)) do
        flag.Captured:Connect(function(player)
            capturedRemote:FireAllClients(flag.State.Team, player)
            self:addPointToTeam(player.Team, 1)
        end)

        flag.Stolen:Connect(function(player)
            stolenRemote:FireAllClients(flag.State.Team, player)
        end)
    end

    local updateConnection = self.UpdateEvent:Connect(function()
        for team, score in pairs(self.scores) do
            if score >= self.config.maxScore then
                self:finish(team)
                break
            end
        end
    end)

    self.destruct = function()
        replicatedRoot:Destroy()
        updateConnection:Disconnect()
    end
end

function CTFServer:addPointToTeam(team, amount)
    local score = self.scores[team] or 0
    self.binder:SetState({[team.Name .. "Score"] = score + amount})
    self.scores[team] = score + amount
end

function CTFServer:finish(winningTeam)
    self.service:AnnounceEvent(("The %s team has won the game!"):format(winningTeam.Name), {
        color = winningTeam.TeamColor.Color;
    })
	self.service:StopGamemode()
end

return CTFServer