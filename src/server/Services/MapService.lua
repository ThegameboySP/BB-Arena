local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Llama = require(ReplicatedStorage.Packages.Llama)

local Binder = require(ReplicatedStorage.Common.Components.Binder)
local t = require(ReplicatedStorage.Packages.t)
local ClonerManager = require(ReplicatedStorage.Common.Component).ClonerManager

local Components = ReplicatedStorage.Common.Components

local metaDefinition = t.strictInterface({
    Teams = t.map(t.string, t.BrickColor);

    IslandTopColor = t.Color3;
    IslandBaseColor = t.Color3;
})

local MapService = Knit.CreateService({
	Name = "MapService";
	Client = {
		PreMapChanged = Knit.CreateSignal();
		MapChanged = Knit.CreateSignal();
		CurrentMap = Knit.CreateProperty(nil);
		MapInfo = Knit.CreateProperty({})
	};
	
	Maps = ServerStorage.Maps;
	LightingSaves = ServerStorage.Plugin_LightingSaves;
	mapParent = workspace.MapRoot;

	PreMapChanged = Signal.new();
	MapChanged = Signal.new();
	
	CurrentMap = nil;
	ChangingMaps = false;
	
	_clonerManager = ClonerManager.new("MapComponents");
	_teamMap = {};
})

function MapService:KnitInit()
	for _, child in pairs(self.mapParent:GetChildren()) do
		if CollectionService:HasTag(child, "Map") then
			child.Parent = self.Maps
		end
	end
	
    local mapInfo = {}
	for _, map in pairs(self.Maps:GetChildren()) do
        mapInfo[map.Name] = true
	end
	
	self.Client.MapInfo:Set(mapInfo)
	
	self.LightingSaves.Name = "LightingSaves"
	self.LightingSaves.Parent = ReplicatedStorage

	RunService.Heartbeat:Connect(function()
		for _, player in pairs(Players:GetPlayers()) do
			if CollectionService:HasTag(player.Team, "FightingTeam") then
				CollectionService:AddTag(player, "FightingPlayer")
			else
				CollectionService:RemoveTag(player, "FightingPlayer")
			end
		end
	end)
end

function MapService:RegisterComponent(class)
	if class.realm ~= "client" then
		self._clonerManager:Register(class)
	end
end

function MapService:KnitStart()
	for _, child in pairs(Components:GetChildren()) do
		self:RegisterComponent(require(child))
	end
end

function MapService:ChangeMap(mapName)
	if self.CurrentMap and self.CurrentMap.Name == mapName then
        return
    end

	local newMap = self.Maps:FindFirstChild(mapName)
	if newMap == nil then
		error(("No map name called: %q"):format(mapName))
	end
	
    local meta = require(newMap:FindFirstChild("Meta") or error("No Meta under " .. mapName))
    assert(metaDefinition(meta))

	self.ChangingMaps = true

	local oldMap = self.CurrentMap
	if oldMap then
		oldMap.Parent = self.Maps
	end

	-- Should reconcile teams before components run.
	local oldTeamToNewTeam = self:_reconcileTeams(meta.Teams)
	self._teamMap = meta.Teams

	self._clonerManager:Clear()
	self._clonerManager:ServerInit(newMap)
	self._clonerManager.Cloner:RunPrototypes(function(record)
		return not record.parent:GetAttribute("Prototype_DisableRun")
	end)
	local componentsToReplicate = self._clonerManager:Flush()

	local mapScript = newMap:FindFirstChild("MapScript")
	if mapScript then
		self._clonerManager.Manager:AddComponent(mapScript, Binder)
	end

	local repFirst = newMap:FindFirstChild("ReplicateFirst")
	if repFirst then
		repFirst.Parent = self.mapParent
	end

	self.CurrentMap = newMap
	self.PreMapChanged:Fire(newMap, oldMap, oldTeamToNewTeam)
	self.Client.PreMapChanged:FireAll(newMap.Name, oldMap and oldMap.Name or nil)

	newMap.Parent = self.mapParent

	if repFirst then
		repFirst.Parent = newMap
	end
	
	for _, player in pairs(CollectionService:GetTagged("FightingPlayer")) do
        task.spawn(player.LoadCharacter, player)
	end
	
	self._clonerManager:ReplicateToClients(componentsToReplicate)

	self.ChangingMaps = false

	self.MapChanged:Fire(newMap)
	self.Client.CurrentMap:Set(newMap)
end

local function makeTeam(name, color)
	local newTeam = Instance.new("Team")
	CollectionService:AddTag(newTeam, "Map")
	CollectionService:AddTag(newTeam, "FightingTeam")

	newTeam.Name = name
	newTeam.TeamColor = color
	newTeam.AutoAssignable = false
	
	return newTeam
end

function MapService:_reconcileTeams(newTeamMap)
    local newTeamByPlayersToSet = {}
	local newTeams = {}
	local existingTeamToNewTeam = {}
	
	for name, color in pairs(newTeamMap) do
		local newTeam = makeTeam(name, color)
		table.insert(newTeams, newTeam)
	end
	
	local newTeamIndex = 1

	for name in pairs(self._teamMap) do
		local existingTeam = Teams:FindFirstChild(name)
		local newTeam = newTeams[newTeamIndex]

		if newTeam and existingTeam then
			local players = existingTeam:GetPlayers()

			if #players > 0 then
				newTeamByPlayersToSet[newTeam] = players
				newTeamIndex += 1
			end

			existingTeamToNewTeam[existingTeam] = newTeam
		elseif existingTeam and not newTeam then
			for _, player in existingTeam:GetPlayers() do
				player.Team = Teams.Spectators
				player:LoadCharacter()
			end

			existingTeamToNewTeam[existingTeam] = Llama.None
		end
		
		if existingTeam then
			existingTeam:Destroy()
		end
	end
	
	for _, newTeam in pairs(newTeams) do
		newTeam.Parent = Teams
	end
	
	for newTeam, players in pairs(newTeamByPlayersToSet) do
		for _, player in pairs(players) do
			player.Team = newTeam
		end
	end

	return table.freeze(existingTeamToNewTeam)
end

return MapService