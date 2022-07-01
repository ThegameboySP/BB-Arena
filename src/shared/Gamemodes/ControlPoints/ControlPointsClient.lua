local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = require(ReplicatedStorage.Common.Root)
local Components = require(ReplicatedStorage.Common.Components)
local ControlPointsGUI = ReplicatedStorage.UI.ControlPointsGUI
local Sounds = ReplicatedStorage.Assets.Sounds
local Assets = script.Parent.ControlPointsAssets

local ControlPointsClient = {}
ControlPointsClient.__index = ControlPointsClient

local LocalPlayer = Players.LocalPlayer

local function playSound(sound)
	local clone = sound:Clone()
	clone.Ended:Connect(function()
		clone.Parent = nil
	end)
	clone:Play()
	clone.Parent = workspace
end

local function playSoundAt(sound, pos)
	local part = Instance.new("Part")
	part.CFrame = CFrame.new(pos)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Name = "SoundHolder"
	part.Size = Vector3.zero

	local clone = sound:Clone()
	clone.Parent = part
	clone.Ended:Connect(function()
		part.Parent = nil
	end)
	clone:Play()

	part.Parent = workspace
end

function ControlPointsClient.new(binder)
	return setmetatable({
		_binder = binder;
		_gui = nil;
		connections = {};
		instancesToDestroy = {};
	}, ControlPointsClient)
end

function ControlPointsClient:Destroy()
	for _, instance in pairs(self.instancesToDestroy) do
		instance:Destroy()
	end

	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
end

function ControlPointsClient:OnInit(teams)
	self.teams = teams

    local MapController = Root:GetService("MapController")
	local controlPoints = {}

	local lastAlerted = 0

    for _, controlPoint in pairs(MapController.ClonerManager.Manager:GetComponents(Components.C_ControlPoint)) do
		table.insert(controlPoints, controlPoint)

		local isInvisible = controlPoint.Instance.FlagHead.Transparency == 1
		
		local flash = Assets.FlashParticles:Clone()
		flash.Parent = controlPoint.Instance.FlagHead

		local lastState
		local function onControlPointUpdated()
			local state = controlPoint.State.State

			if 
				(state == "Capping" or state == "Paused") and lastState == "Settled"
				and controlPoint.State.CapturedBy == LocalPlayer.Team
				and controlPoint.State.CapturingGroup ~= LocalPlayer.Team
			then
				if (os.clock() - lastAlerted) > 30 then
					lastAlerted = os.clock()

					if controlPoint.Config.IsCenter then
						playSound(Sounds.CP_BadCenterCapturing)
					else
						playSound(Sounds.CP_BadCapturing)
					end
				end
			end

			if not isInvisible then
				flash.Enabled = state == "Capping"
			end
			
			lastState = state
		end

        table.insert(self.connections, controlPoint.Changed:Connect(onControlPointUpdated))
		onControlPointUpdated()

		local confettiHolder = Assets.ConfettiHolder:Clone()
		local teamConfetti = confettiHolder:FindFirstChild("TeamConfetti")
		local confetti = confettiHolder:FindFirstChild("Confetti")
		table.insert(self.instancesToDestroy, confettiHolder)
		
		local CF, size = controlPoint.Instance:GetBoundingBox()
		confettiHolder.CFrame = CF * CFrame.new(0, size.Y / 2, 0)
		confettiHolder.Parent = workspace

		local lastCapturedBy = controlPoint.State.Captured
		table.insert(self.connections, controlPoint.Instance.Captured.OnClientEvent:Connect(function(capturedBy)
			teamConfetti.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, capturedBy.TeamColor.Color),
				ColorSequenceKeypoint.new(1, capturedBy.TeamColor.Color:lerp(Color3.new(0, 0, 0), 0.4))
			})

			for _, confettiEmitter in pairs({confetti, teamConfetti}) do
				confettiEmitter:Emit(100)
			end

			if capturedBy == LocalPlayer.Team then
				playSound(Sounds.CP_GoodCaptured)
				playSound(Sounds.Tada)
			else
				if lastCapturedBy == LocalPlayer.Team then
					playSound(Sounds.CP_BadCaptured)
				end

				playSound(Sounds.Splat)
			end

			lastCapturedBy = capturedBy
		end))
	end

	table.insert(self.connections, ReplicatedStorage.ControlPointsValues.Healed.OnClientEvent:Connect(function(character)
		local emitter = Assets.HealParticles:Clone()
		emitter.Parent = character.HumanoidRootPart
		emitter.Enabled = true

		task.delay(1, function()
			emitter.Enabled = false
			task.delay(2, function()
				emitter.Parent = nil
			end)
		end)

		playSoundAt(Sounds.Copy, character.Head.Position)
	end))
	
	self:_handleGUI(controlPoints)
end

local function find(instance, ...)
	local current = instance
	for _, name in pairs({...}) do
		current = current:FindFirstChild(name)
	end

	return current
end

local NEUTRAL = Color3.fromRGB(158, 171, 197)
local function setGradient(gradient, capturedBy, capturing, percent)
	if capturedBy and not capturing and percent == 0 then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, capturedBy.TeamColor.Color),
			ColorSequenceKeypoint.new(1, capturedBy.TeamColor.Color)
		})
		return
	end

	local base = capturedBy and capturedBy.TeamColor.Color or NEUTRAL
	local color = capturing and capturing.TeamColor.Color or NEUTRAL
	local inversePercent = math.min(0.9998, 1 - percent)

	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, base),
		ColorSequenceKeypoint.new(inversePercent, base),
		ColorSequenceKeypoint.new(math.min(0.9999, inversePercent + 0.02), color),
		ColorSequenceKeypoint.new(1, color)
	})
end

function ControlPointsClient:_handleGUI(controlPoints)
	local Gui = ControlPointsGUI:Clone()
	table.insert(self.instancesToDestroy, Gui)

	local Points = find(Gui, "Background", "Points")
	local PointTemp = Points:FindFirstChild("PointTemp")
	local Scores = find(Gui, "Background", "Scores")
	local BarHolder = find(Gui, "Background", "Scores", "BarHolder")
	local Info = find(Gui, "Background", "Scores", "Info")
	PointTemp.Parent = nil

	for _, point in pairs(controlPoints) do
		local Point = PointTemp:Clone()
		Point.Name = string.char(point.Config.Order)
		if point.Config.IsCenter then
			Point.Size = UDim2.fromScale(0.25, 0.8)
		end

		local function update()
			Point:FindFirstChild("Count").Text =
				((point.State.TeammatesCount or 0) > 0 and point.State.State ~= "Paused")
				and tostring(point.State.TeammatesCount)
				or ""
			
			setGradient(
				Point:FindFirstChild("UIGradient"),
				point.State.CapturedBy,
				point.State.CapturingGroup,
				point.State.PercentOverthrown)
		end

		table.insert(self.connections, point.Changed:Connect(update))
		update()

		Point.Parent = Points
	end

	local function updateScore()
		local maxSize = Info.AbsolutePosition.X - BarHolder.AbsolutePosition.X - 5

		local scoreA = self._binder.State[self.teams[1].Name .. "Score"] or 0
		local scoreB = self._binder.State[self.teams[2].Name .. "Score"] or 0
		local maxScore = self._binder.State.maxScore or 0

		Info.ScoreA.Text = tostring(math.floor(scoreA))
		Info.ScoreB.Text = tostring(math.floor(scoreB))

		Info.MaxScore.Text = tostring(math.floor(maxScore))

		BarHolder.BarA.Size = UDim2.new(0, math.max(0, scoreA / maxScore) * maxSize, 1, 0)
		BarHolder.BarB.Size = UDim2.new(0, math.max(0, scoreB / maxScore) * maxSize, 1, 0)

		Scores.ToWin.Text = self._binder.State.WinningName or ""
	end

	BarHolder.BarA.BackgroundColor3 = self.teams[1].TeamColor.Color
	BarHolder.BarB.BackgroundColor3 = self.teams[2].TeamColor.Color

	table.insert(self.connections, self._binder.Changed:Connect(updateScore))
	updateScore()

	Gui.Parent = LocalPlayer.PlayerGui
end

return ControlPointsClient