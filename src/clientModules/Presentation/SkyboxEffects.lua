local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local import = require(game:GetService("ReplicatedStorage"):WaitForChild("Import"))
local Maid = import("Game", "Maid")

local SkyboxEffectsGui = {}
SkyboxEffectsGui.__index = SkyboxEffectsGui

local DEFAULT_CAMERA_DEPTH = 2000

function SkyboxEffectsGui.new()
	local maid = Maid.new()
	
	local part = Instance.new("Part")
	part.Name = "SkyboxEffectsAdornee"
	part.Anchored = true
	part.Size = Vector3.new(1,1,1)
	part.CanCollide = false
	part.Transparency = 1

	local gui = Instance.new("BillboardGui")
	local currentCam

	local function onCurrentCameraChanged()
		local function onViewportSizeChanged()
			gui.Size = UDim2.fromOffset(currentCam.ViewportSize.X, currentCam.ViewportSize.Y)
		end
		currentCam = workspace.CurrentCamera
		maid.size = currentCam:GetPropertyChangedSignal("ViewportSize"):Connect(onViewportSizeChanged)
		onViewportSizeChanged()
	end

	maid.cam = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(onCurrentCameraChanged)
	onCurrentCameraChanged()

	gui.ResetOnSpawn = false
	gui.Name = "Effects"
	gui.Parent = Players.LocalPlayer.PlayerGui

	part.Parent = workspace
	gui.Adornee = part

	local self = setmetatable({
		_gui = gui;
		_maid = maid;
		_effects = {};
		_enabled = true;
	}, SkyboxEffectsGui)

	local id = HttpService:GenerateGUID()
	RunService:BindToRenderStep(id, Enum.RenderPriority.Camera.Value + 1, function()
		if self._enabled then
		    part.CFrame = currentCam.CFrame:ToWorldSpace(CFrame.new(0, 0, -DEFAULT_CAMERA_DEPTH))
        end
	end)
	
	maid:GiveTask(function()
		gui:Destroy()
		RunService:UnbindFromRenderStep(id)
	end)

	return self
end

function SkyboxEffectsGui:Destroy()
	self._maid:DoCleaning()
	for effect in next, self._effects do
		effect:Destroy()
	end
end


function SkyboxEffectsGui:AddEffect(effect)
	assert(type(effect) == "table")
	effect:Adorn(self:GetRoot(), workspace)
	self._effects[effect] = true
	
	return effect
end


function SkyboxEffectsGui:RemoveEffect(effect)
	assert(type(effect) == "table")
	self._effects[effect] = nil
end


function SkyboxEffectsGui:SetEnabled(enabled)
	self._enabled = enabled
end


function SkyboxEffectsGui:GetRoot()
	return self._gui
end

return SkyboxEffectsGui