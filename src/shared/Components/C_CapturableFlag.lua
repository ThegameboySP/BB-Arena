local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Common.Component).Component
local Bin = require(ReplicatedStorage.Common.Utils.Bin)
local C_CapturableFlag = Component:extend("CapturableFlag", {
	realm = "client",
})

function C_CapturableFlag:OnInit()
	local flagHead = self.Instance.FlagHead
	local pole = self.Instance.Pole

	local poleTopPos = pole.Position + Vector3.new(0, pole.Size.X / 2, 0)

	self.bin = Bin.new()

	self._pivotCFrame = flagHead:GetPivot()
	self._flagHead = flagHead
	self._flagHeadTopPos = flagHead.Position
	self._flagHeadBottomPos = poleTopPos - Vector3.new(0, pole.Size.X * 0.85, 0)
	self._flagHeadDistance = (self._flagHeadTopPos - self._flagHeadBottomPos).Magnitude
	self._decal = self.Instance.FlagHead:FindFirstChildWhichIsA("Decal")
end

function C_CapturableFlag:Destroy()
	self.bin:DoCleaning()
end

function C_CapturableFlag:OnStart()
	self._radius = self.Instance:WaitForChild("Radius")

	local function update(new, old)
		if new.PercentOverthrown == old.PercentOverthrown then
			return
		end

		local percent = new.PercentOverthrown
		local color = self.getFlagColor(self.State.CapturedBy, self.State.CapturingGroup, percent)
		self._decal.Color3 = color
		self._radius.Color = color

		local offset
		if percent < 0.5 then
			offset = -Vector3.new(0, percent * 2 * self._flagHeadDistance, 0)
		else
			offset = Vector3.new(0, (percent - 0.5) * 2 * self._flagHeadDistance - self._flagHeadDistance, 0)
		end

		self._flagHead:PivotTo(self._pivotCFrame * CFrame.new(offset))
	end

	self.bin:Add(self.Changed:Connect(update))
	update(self.State, {})

	self.Instance.Radius.Transparency = 0.6
	local tween = TweenService:Create(
		self.Instance.Radius,
		TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.8 }
	)

	self.bin:Add(tween, "Cancel")
	tween:Play()
end

return C_CapturableFlag
