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
local LocalPlayer = game:GetService("Players").LocalPlayer

function MapController:KnitInit()
	local MapService = Knit.GetService("MapService")

	-- Clear Studio lighting preset.
	Lighting:ClearAllChildren()

	MapService.PreMapChanged:Connect(function(mapName, oldMapName)
		self.PreMapChanged:Fire(mapName, oldMapName)
	end)

	MapService.CurrentMap:Observe(function(map)
		self:_onMapChanged(map)
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

function MapController:_onMapChanged(map)
	if self._tween then
		self._tween:Cancel()

		for key, value in pairs(self._tweenProps) do
			Lighting[key] = value
		end
	end

	local oldMap = self.CurrentMap
	self.CurrentMap = map
	self.MapChanged:Fire(map, oldMap)

	local lightingEntry = self:_getLightingEntryOrWarn(map.Name)
	if lightingEntry then
		self._skyboxTweener:TweenSkybox(lightingEntry:FindFirstChildWhichIsA("Sky", true):Clone(), FADE_INFO)

		self._tweenProps = {}
		for _, child in pairs(lightingEntry.Lighting:GetChildren()) do
			if child:IsA("ValueBase") then
				self._tweenProps[child.Name] = child.Value
			end
		end

		for _, child in pairs(lightingEntry.InLighting:GetChildren()) do
			if not child:IsA("Sky") then
				child:Clone().Parent = Lighting
			end
		end

		self._tween = TweenService:Create(Lighting, FADE_INFO, self._tweenProps)
		self._tween:Play()
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