local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local CTFScoreGUI = ReplicatedStorage.UI.CTFScoreGUI
local Sounds = ReplicatedStorage.Assets.Sounds

local CTFClient = {}
CTFClient.__index = CTFClient

local LocalPlayer = Players.LocalPlayer

local function playSound(sound)
	local clone = sound:Clone()
	clone.Ended:Connect(function()
		clone.Parent = nil
	end)

	clone.SoundGroup = SoundService.Gamemode
	clone:Play()
	clone.Parent = workspace
end

function CTFClient.new(binder)
	return setmetatable({
		binder = binder,
		_gui = nil,
		connections = {},
		instancesToDestroy = {},
	}, CTFClient)
end

function CTFClient:Destroy()
	for _, instance in pairs(self.instancesToDestroy) do
		instance:Destroy()
	end

	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
end

function CTFClient:OnInit(teams)
	self.teams = teams

	self.service:GetRemoteEvent("CTF_Captured").OnClientEvent:Connect(function(data)
		if LocalPlayer.Team == data.team then
			playSound(Sounds.LaunchingRocket)
		else
			playSound(Sounds.Tada)
		end
	end)

	self.service:GetRemoteEvent("CTF_Stolen").OnClientEvent:Connect(function(data)
		if LocalPlayer.Team == data.team then
			playSound(Sounds.Splat)
		else
			playSound(Sounds.Button)
		end
	end)

	self:_handleGUI(teams)
end

function CTFClient:_handleGUI(teams)
	local Gui = CTFScoreGUI:Clone()
	local scores = Gui:FindFirstChild("Scores")
	local temp = Gui:FindFirstChild("Temp")
	temp.Parent = nil

	table.insert(self.instancesToDestroy, Gui)

	local guisByTeam = {}
	for _, team in ipairs(teams) do
		local clone = temp:Clone()
		clone.TextColor3 = team.TeamColor.Color
		clone.TextStrokeColor3 = team.TeamColor.Color:Lerp(Color3.new(0, 0, 0), 0.5)
		clone.Parent = scores

		guisByTeam[team] = clone
	end

	local function updateScore()
		Gui:FindFirstChild("Goal").Text = string.format("To %s", tostring(self.binder.State.maxScore) or "0")
		for team, gui in pairs(guisByTeam) do
			gui.Text = tostring(self.binder.State[team.Name .. "Score"])
		end
	end

	table.insert(self.connections, self.binder.Changed:Connect(updateScore))
	updateScore()

	Gui.Parent = LocalPlayer.PlayerGui
end

return CTFClient
