local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Bin = require(ReplicatedStorage.Common.Utils.Bin)
local ScoreGui = script.Parent.ScoreGui

local ScrimmageClient = {}
ScrimmageClient.UpdateEvent = RunService.Heartbeat
ScrimmageClient.__index = ScrimmageClient

function ScrimmageClient.new()
    return setmetatable({
        replicatedRoot = nil;
        bin = Bin.new();
        queue = {};
    }, ScrimmageClient)
end

function ScrimmageClient:OnInit()
    self.replicatedRoot = ReplicatedStorage:WaitForChild("Scrimmage_ReplicatedRoot")

    self.bin:Add(ScrimmageClient.UpdateEvent:Connect(function()
        for callback in self.queue do
            callback()
        end
    
        table.clear(self.queue)
    end))

    self:_handleGui()
end

function ScrimmageClient:Destroy()
    self.bin:DoCleaning()
end

function ScrimmageClient:_handleGui()
    local gui = self.bin:Add(ScoreGui:Clone())
    local toLabel = gui.Frame.ToScore
    local scores = gui.Frame.Scores
    
    local scoreTemplate = scores.ScoreTemp
    scoreTemplate.Parent = nil

    local function updateGui()
        local toScore = self.replicatedRoot:GetAttribute("MaxScore")
        toLabel.Text = string.format("To: %s", tostring(math.floor(toScore)))

        local scoresByTeam = {}
        for key, value in self.replicatedRoot:GetAttributes() do
            local team = Teams:FindFirstChild(key)
            if team then
                scoresByTeam[team] = value
            end
        end

        for _, child in scores:GetChildren() do
            if child:IsA("TextLabel") then
                child.Parent = nil
            end
        end

        for team, score in scoresByTeam do
            local scoreLabel = scoreTemplate:Clone()
            scoreLabel.Name = team.Name
            scoreLabel.TextColor3 = team.TeamColor.Color
            scoreLabel.Text = tostring(score)
            scoreLabel.Parent = scores
        end
    end

    local function addToQueue()
        self.queue[updateGui] = true
    end
    
    self.bin:Add(self.replicatedRoot.AttributeChanged:Connect(addToQueue))
    updateGui()

    gui.Parent = Players.LocalPlayer.PlayerGui
end

return ScrimmageClient