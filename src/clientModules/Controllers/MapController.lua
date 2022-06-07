local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Binder = require(ReplicatedStorage.Common.Components.Binder)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SkyboxTweener = require(ReplicatedStorage.ClientModules.Presentation.SkyboxTweener)
local ClonerManager = require(ReplicatedStorage.Common.Component).ClonerManager

local Components = require(ReplicatedStorage.Common.Components)

local MapController = Knit.CreateController({
	Name = "MapController";

	MapChanged = Signal.new();
	PreMapChanged = Signal.new();

	CurrentMap = nil;

 	_skyboxTweener = SkyboxTweener.new(Lighting);
	ClonerManager = ClonerManager.new("MapComponents");
})

local FADE_INFO = TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local TIME_FADE_INFO = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)

function MapController:KnitInit()
	for _, component in Components do
		self:RegisterComponent(component)
	end
end

function MapController:RegisterComponent(class)
	if class.realm ~= "server" then
		self.ClonerManager:Register(class)
	end
end

function MapController:KnitStart()
	local MapService = Knit.GetService("MapService")

	MapService.PreMapChanged:Connect(function(mapName, oldMapName)
		self:_tween(mapName)
		self.PreMapChanged:Fire(mapName, oldMapName)
	end)

	MapService.CurrentMap:OnReady():andThen(function()
		self:_tween(MapService.CurrentMap:Get().Name)
	end)
end

function MapController:onMapChanged(map)
	local oldMap = self.CurrentMap
	self.CurrentMap = map

	self.ClonerManager:Clear()
	self.ClonerManager:ClientInit(map)
	self.ClonerManager:Flush()
	self.ClonerManager.Cloner:RunPrototypes(function()
		return true
	end)

	local mapScript = map:FindFirstChild("MapScript")
	if mapScript then
		self.ClonerManager.Manager:AddComponent(mapScript, Binder)
	end

	self.MapChanged:Fire(map, oldMap)
end

function MapController:_tween(mapName)
	if self._lightingCleanupFn then
		self._lightingCleanupFn()
	end

	local lightingEntry = self:_getLightingEntryOrWarn(mapName)
	if lightingEntry then
		for _, child in pairs(Lighting:GetChildren()) do
			if not child:IsA("Sky") and CollectionService:HasTag(child, "MapBound") then
				child.Parent = nil
			end
		end

		local skybox = lightingEntry:FindFirstChildWhichIsA("Sky", true):Clone()
		CollectionService:AddTag(skybox, "MapBound")
		
		self._skyboxTweener:TweenSkybox(skybox, FADE_INFO, function()
			for _, child in pairs(Lighting:GetChildren()) do
				if child:IsA("Sky") and CollectionService:HasTag(child, "MapBound") then
					child.Parent = nil
				end
			end
		end)

		local tweenProps = {}
		for _, child in pairs(lightingEntry.Lighting:GetChildren()) do
			if child:IsA("ValueBase") and child.Name ~= "ClockTime" then
				tweenProps[child.Name] = child.Value
			end
		end

		for _, child in pairs(lightingEntry.InLighting:GetChildren()) do
			if not child:IsA("Sky") then
				local clone = child:Clone()
				CollectionService:AddTag(clone, "MapBound")
				clone.Parent = Lighting
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

function MapController:_getLightingEntryOrWarn(name)
	local entry = ReplicatedStorage.LightingSaves:FindFirstChild(name)
	if entry then
		return entry
	end
	
	warn("No lighting entry for", name)
end

return MapController