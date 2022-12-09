local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage.Common.Gamemodes.CTF.CTFAssets

local Component = require(ReplicatedStorage.Common.Component).Component
local Bin = require(ReplicatedStorage.Common.Utils.Bin)

local C_CTF_Flag = Component:extend("CTF_Flag", {
	realm = "client",
	UpdateEvent = RunService.Heartbeat,
})

local SPIN_SPEED = math.pi * 2 * (1 / 4)
local TIME_LEFT_FORMAT = "Time left: %.2f"
local PULSE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)

function C_CTF_Flag:OnStart()
	self.confetti = {}
	self.bin = Bin.new()

	local h, s = self.State.Team.TeamColor.Color:ToHSV()
	local teamColor = Color3.fromHSV(h, s, 1)
	for _ = 1, 5 do
		local confetti = Assets.Confetti:Clone()
		local clone = confetti:Clone()
		clone.Color = ColorSequence.new(teamColor:lerp(Color3.new(0, 0, 0), math.random(20, 100) / 100))
		clone.Parent = self.Instance

		table.insert(self.confetti, clone)
	end

	local brightness = self.Instance.PointLight.Brightness
	local range = self.Instance.PointLight.Range

	self.Changed:Connect(function(new, old)
		if new.State == old.State then
			return
		end

		self:_changeState(new.State)

		if new.State == "Docked" then
			self.bin:Remove("flash")
		elseif not self.bin:Get("flash") then
			local tween = TweenService:Create(self.Instance.Texture, PULSE_TWEEN_INFO, { Transparency = 0.7 })

			local pointLight = self.Instance.PointLight
			pointLight.Range = range * 0.7
			pointLight.Brightness = brightness * 0.7

			local tween2 = TweenService:Create(pointLight, PULSE_TWEEN_INFO, { Range = range, Brightness = brightness })

			self.bin:AddId(function()
				tween:Cancel()
				tween2:Cancel()
				self.Instance.Texture.Transparency = 0
				self.Instance.PointLight.Brightness = brightness
				self.Instance.PointLight.Range = range
			end, "flash")

			tween:Play()
			tween2:Play()
		end
	end)

	self.bin:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if
			not gameProcessed
			and input.UserInputType == Enum.UserInputType.Keyboard
			and input.UserInputState == Enum.UserInputState.Begin
			and input.KeyCode == Enum.KeyCode.Backspace
		then
			self:RemoteEvent("Drop"):FireServer()
		end
	end))

	self:RemoteEvent("PickedUp").OnClientEvent:Connect(function()
		for _, emitter in ipairs(self.confetti) do
			emitter:Emit(50)
		end
	end)
end

function C_CTF_Flag:_changeState(state, ...)
	self.bin:Remove("stateBin")

	local method = self["_" .. state:sub(1, 1):lower() .. state:sub(2, -1)]
	if type(method) == "function" then
		method(self, Bin.new(), ...)
	end
end

function C_CTF_Flag:_dropped(bin)
	self.bin:AddId(bin, "stateBin")
	bin:Add(self.UpdateEvent:Connect(function(dt)
		self.Instance.CFrame *= CFrame.Angles(0, 0, dt * SPIN_SPEED)
	end))

	local gui = bin:Add(Assets.DroppedGui:Clone())
	gui.Parent = self.Instance

	bin:Add(self.Changed:Connect(function(new, old)
		if new.TimeLeft ~= old.TimeLeft then
			gui.Timer.Text = string.format(TIME_LEFT_FORMAT, new.TimeLeft)
		end
	end))
end

return C_CTF_Flag
