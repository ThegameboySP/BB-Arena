local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Binder = require(ReplicatedStorage.Common.Components.Binder)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SkyboxTweener = require(ReplicatedStorage.ClientModules.Presentation.SkyboxTweener)
local ClonerManager = require(ReplicatedStorage.Common.Component).ClonerManager

local Components = require(ReplicatedStorage.Common.Components)

local MapController = {
	Name = "MapController",

	MapChanged = Signal.new(),
	MapChanging = Signal.new(),

	CurrentMap = nil,
	MapScript = nil,

	_skyboxTweener = SkyboxTweener.new(Lighting),
	ClonerManager = ClonerManager.new("MapComponents"),
}

local FADE_INFO = TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local TIME_FADE_INFO = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)

local DEFAULT_TOP_COLOR = Color3.fromRGB(92, 114, 84)
local DEFAULT_BASE_COLOR = Color3.fromRGB(108, 88, 75)

function MapController:OnInit()
	for _, component in Components do
		self:RegisterComponent(component)
	end
end

function MapController:RegisterComponent(class)
	if class.realm ~= "server" then
		self.ClonerManager:Register(class)
	end
end

function MapController:OnStart()
	self.MapService = self.Root:GetServerService("MapService")
	self:_tween(self.MapService.CurrentMap:Get().Name)
end

function MapController:onMapChanging(mapName, oldMapName)
	self.ClonerManager:Clear()
	self:_tween(mapName)
	self.MapChanging:Fire(mapName, oldMapName)
end

function MapController:onMapChanged(map)
	local oldMap = self.CurrentMap
	self.CurrentMap = map
	self.MapScript = nil

	self.ClonerManager:ClientInit(map)
	self.ClonerManager:Flush()
	self.ClonerManager.Cloner:RunPrototypes(function()
		return true
	end)

	local mapScript = map:FindFirstChild("MapScript")
	if mapScript then
		self.MapScript = self.ClonerManager.Manager:AddComponent(mapScript, Binder)
	end

	self.MapChanged:Fire(map, oldMap)

	self.MapService.PlayerStreamedMap:FireServer()
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

		local skybox = lightingEntry:FindFirstChildWhichIsA("Sky", true)
		local removeSkybox = function()
			for _, child in pairs(Lighting:GetChildren()) do
				if child:IsA("Sky") and CollectionService:HasTag(child, "MapBound") then
					child.Parent = nil
				end
			end
		end

		if skybox then
			self._skyboxTweener._fakeSkybox._viewport.Visible = true
			local clone = skybox:Clone()
			CollectionService:AddTag(clone, "MapBound")

			self._skyboxTweener:TweenSkybox(clone, FADE_INFO, removeSkybox)
		else
			self._skyboxTweener._fakeSkybox._viewport.Visible = false
			removeSkybox()
		end

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

		local tweens = {}
		table.insert(tweens, {
			goal = tweenProps,
			tween = TweenService:Create(Lighting, FADE_INFO, tweenProps),
		})

		table.insert(tweens, {
			goal = { ClockTime = lightingEntry.Lighting.ClockTime.Value },
			tween = TweenService:Create(
				Lighting,
				TIME_FADE_INFO,
				{ ClockTime = lightingEntry.Lighting.ClockTime.Value }
			),
		})

		local meta = self.Root.globals.mapInfo:Get()[mapName]

		for _, part in CollectionService:GetTagged("IslandBase") do
			local goal = meta.IslandTopColor or DEFAULT_TOP_COLOR
			table.insert(tweens, {
				goal = { Color = goal },
				tween = TweenService:Create(part, FADE_INFO, { Color = goal }),
			})
		end

		for _, part in CollectionService:GetTagged("IslandBase") do
			local goal = meta.IslandBaseColor or DEFAULT_BASE_COLOR
			table.insert(tweens, {
				goal = { Color = goal },
				tween = TweenService:Create(part, FADE_INFO, { Color = goal }),
			})
		end

		for _, record in tweens do
			-- TweenService has a bug going from larger to smaller values where the result is 0.
			-- This is a patch to fix that.
			record.tween.Completed:Once(function()
				for key, value in record.goal do
					record.tween.Instance[key] = value
				end
			end)
			record.tween:Play()
		end

		self._lightingCleanupFn = function()
			for _, tween in tweens do
				tween.tween:Cancel()
			end

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
