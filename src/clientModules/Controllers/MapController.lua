local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local MapController = Knit.CreateController({
	Name = "MapController";

	MapChanged = Signal.new();
	PreMapChanged = Signal.new();

	CurrentMap = nil;
	
	-- _fakeSkybox = FakeSkybox.new();
	-- _skyboxEffects = SkyboxEffectsGui.new();
	-- _maid = Maid.new()
})

local FADE_INFO = TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local TIME_FADE_INFO = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local LOCAL_PLAYER = game:GetService("Players").LocalPlayer

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
		if CollectionService:HasTag(LOCAL_PLAYER, "FightingPlayer") then
            return
        end
        
		workspace.CurrentCamera.Focus = CFrame.new(Vector3.new(0, 0, 0))
	end)
end

function MapController:_onMapChanged(map)
	local oldMap = self.CurrentMap
	self.CurrentMap = map
	self.MapChanged:Fire(map, oldMap)
end

function getLightingEntryOrWarn(name)
	local entry = LightingSaves:FindFirstChild(name)
	if entry == nil then
		return warn("No lighting entry for", name)
	end
	
	return entry
end

function tweenIslandColors(newMap)
	local config = newMap:FindFirstChild("Configuration")
	
	if not config then
		return warn("No map configuration for", newMap)
	end
	
	local topDefault = Color3.fromRGB(80,109,84)
	local baseDefault = Color3.fromRGB(108,88,75)
	
	local topNew = config:GetAttribute("IslandTopColor") or topDefault
	local baseNew = config:GetAttribute("IslandBaseColor") or baseDefault

	for _ ,part in next, Islands.Top:GetChildren() do
		TweenService:Create(part, FADE_INFO, {Color = topNew}):Play()
	end
	
	for _, part in next, Islands.Base:GetChildren() do
		TweenService:Create(part, FADE_INFO, {Color = baseNew}):Play()
	end
end

return MapController