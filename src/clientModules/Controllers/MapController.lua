local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SkyboxTweener = require(ReplicatedStorage.ClientModules.Presentation.SkyboxTweener)

local MapController = Knit.CreateController({
	Name = "MapController";

	MapChanged = Signal.new();
	PreMapChanged = Signal.new();

	CurrentMap = nil;

 	_skyboxTweener = SkyboxTweener.new(Lighting);
})

local FADE_INFO = TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local TIME_FADE_INFO = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local LocalPlayer = game:GetService("Players").LocalPlayer

function MapController:KnitInit()
	local MapService = Knit.GetService("MapService")

	-- Clear Studio lighting preset.
	Lighting:ClearAllChildren()

	MapService.PreMapChanged:Connect(function(mapName, oldMapName)
		self:_tween(mapName)
		self.PreMapChanged:Fire(mapName, oldMapName)
	end)

	MapService.CurrentMap:Observe(function(map)
		self:_onMapChanged(map)
	end)

	MapService.CurrentMap:OnReady():andThen(function()
		self:_tween(MapService.CurrentMap:Get().Name)
	end)
end

function MapController:KnitStart()
	-- Focus all render power onto the map, regardless of where you are.
	RunService:BindToRenderStep("CamFocus", Enum.RenderPriority.Camera.Value, function()
		if CollectionService:HasTag(LocalPlayer, "FightingPlayer") then
            return
        end
        
		workspace.CurrentCamera.Focus = CFrame.new(Vector3.new(0, 0, 0))
	end)
end

function MapController:_tween(mapName)
	if self._lightingCleanupFn then
		self._lightingCleanupFn()
	end

	local lightingEntry = self:_getLightingEntryOrWarn(mapName)
	if lightingEntry then
		Lighting:ClearAllChildren()
		self._skyboxTweener:TweenSkybox(lightingEntry:FindFirstChildWhichIsA("Sky", true):Clone(), FADE_INFO)

		local tweenProps = {}
		for _, child in pairs(lightingEntry.Lighting:GetChildren()) do
			if child:IsA("ValueBase") and child.Name ~= "ClockTime" then
				tweenProps[child.Name] = child.Value
			end
		end

		for _, child in pairs(lightingEntry.InLighting:GetChildren()) do
			if not child:IsA("Sky") then
				child:Clone().Parent = Lighting
			end
		end

		local tween1 = TweenService:Create(Lighting, FADE_INFO, tweenProps)
		local tween2 = TweenService:Create(Lighting, TIME_FADE_INFO, {ClockTime = lightingEntry.Lighting.ClockTime.Value})
		tween1:Play()
		tween2:Play()

		self._lightingCleanupFn = function()
			tween1:Cancel()
			tween2:Cancel()

			for key, value in pairs(tweenProps) do
				Lighting[key] = value
			end
			Lighting.ClockTime = lightingEntry.Lighting.ClockTime.Value
		end
	end
end

function MapController:_onMapChanged(map)
	local oldMap = self.CurrentMap
	self.CurrentMap = map
	self.MapChanged:Fire(map, oldMap)
end

function MapController:_getLightingEntryOrWarn(name)
	local entry = ReplicatedStorage.LightingSaves:FindFirstChild(name)
	if entry then
		return entry
	end
	
	warn("No lighting entry for", name)
end

return MapController