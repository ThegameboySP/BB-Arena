local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SkyboxEffectsGui = {}
SkyboxEffectsGui.__index = SkyboxEffectsGui

local DEFAULT_CAMERA_DEPTH = 2000

function SkyboxEffectsGui.new()
	local part = Instance.new("Part")
	part.Name = "SkyboxEffectsAdornee"
	part.Anchored = true
	part.Size = Vector3.new(1, 1, 1)
	part.CanCollide = false
	part.Transparency = 1

	local gui = Instance.new("BillboardGui")
	local currentCam

	local function onCurrentCameraChanged()
		local function onViewportSizeChanged()
			gui.Size = UDim2.fromOffset(currentCam.ViewportSize.X, currentCam.ViewportSize.Y)
		end
		currentCam = workspace.CurrentCamera
		currentCam:GetPropertyChangedSignal("ViewportSize"):Connect(onViewportSizeChanged)
		onViewportSizeChanged()
	end

	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(onCurrentCameraChanged)
	onCurrentCameraChanged()

	gui.ResetOnSpawn = false
	gui.Name = "Effects"
	gui.Parent = Players.LocalPlayer.PlayerGui

	part.Parent = workspace
	gui.Adornee = part

	local self = setmetatable({
		_gui = gui,
		_effects = {},
		_enabled = true,
		_id = HttpService:GenerateGUID(),
	}, SkyboxEffectsGui)

	RunService:BindToRenderStep(self._id, Enum.RenderPriority.Camera.Value + 1, function()
		if self._enabled then
			part.CFrame = currentCam.CFrame:ToWorldSpace(CFrame.new(0, 0, -DEFAULT_CAMERA_DEPTH))
		end
	end)

	return self
end

function SkyboxEffectsGui:Destroy()
	self._gui.Parent = nil
	RunService:UnbindFromRenderStep(self._id)

	self._maid:DoCleaning()
	for effect in pairs(self._effects) do
		effect:Destroy()
	end
end

function SkyboxEffectsGui:AddEffect(effect)
	effect:Adorn(self:GetRoot(), workspace)
	self._effects[effect] = true

	return effect
end

function SkyboxEffectsGui:RemoveEffect(effect)
	self._effects[effect] = nil
end

function SkyboxEffectsGui:SetEnabled(enabled)
	self._enabled = enabled
end

function SkyboxEffectsGui:GetRoot()
	return self._gui
end

return SkyboxEffectsGui
