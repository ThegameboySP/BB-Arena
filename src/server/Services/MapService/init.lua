local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Binder = require(ReplicatedStorage.Common.Components.Binder)
local t = require(ReplicatedStorage.Packages.t)
local ClonerManager = require(ReplicatedStorage.Common.Component).ClonerManager

local reconcileTeams = require(script.reconcileTeams)

local Components = require(ReplicatedStorage.Common.Components)

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
	};
	
	Maps = ServerStorage.Maps;
	LightingSaves = ServerStorage.Plugin_LightingSaves;
	mapParent = workspace.MapRoot;

	PreMapChanged = Signal.new();
	MapChanged = Signal.new();
	
	CurrentMap = nil;
	ChangingMaps = false;
	MapScript = nil;
	
	ClonerManager = ClonerManager.new("MapComponents");
})

function MapService:KnitInit()
	for _, child in pairs(self.mapParent:GetChildren()) do
		if CollectionService:HasTag(child, "Map") then
			child.Parent = self.Maps
		end
	end
	
    local mapInfo = {}
	for _, map in pairs(self.Maps:GetChildren()) do
        mapInfo[map.Name] = require(map:FindFirstChild("Meta"))
	end

	Knit.globals.mapInfo:Set(table.freeze(mapInfo))
	
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
		self.ClonerManager:Register(class)
	end
end

function MapService:KnitStart()
	for _, component in Components do
		self:RegisterComponent(component)
	end
end

function MapService:Regen(filter)
	filter = filter or function()
		return true
	end

	local prototypes = {}
	local clones = {}

	for _, component in self.ClonerManager.Manager:GetComponents(Components.RegenGroup) do
		if filter(component.Instance) then
			table.insert(clones, component.Instance)
			table.insert(prototypes, self.ClonerManager.Cloner:GetPrototypeByClone(component.Instance))
		end
	end

	for _, clone in clones do
		self.ClonerManager.Cloner:DespawnClone(clone)
	end

	self.ClonerManager.Cloner:RunPrototypes(prototypes)
	
	local components = self.ClonerManager:Flush()
	self.ClonerManager:ReplicateToClients(components)
end

function MapService:ChangeMap(mapName)
	if self.CurrentMap and self.CurrentMap.Name == mapName then
        return false, ("Already playing on map: %q"):format(mapName)
    end

	local newMap = self.Maps:FindFirstChild(mapName)
	if newMap == nil then
		return false, ("No map name called: %q"):format(mapName)
	end
	
    local meta = require(newMap:FindFirstChild("Meta") or error("No Meta under " .. mapName))
    assert(metaDefinition(meta))

	self.ChangingMaps = true
	self.MapScript = nil

	local oldMap = self.CurrentMap
	if oldMap then
		oldMap.Parent = self.Maps
	end

	-- Should reconcile teams before components run.
	local oldTeamToNewTeam = self:_reconcileTeams(meta.Teams)

	self.ClonerManager:Clear()
	self.ClonerManager:ServerInit(newMap)
	self.ClonerManager.Cloner:RunPrototypes(function(record)
		return not record.parent:GetAttribute("Prototype_DisableRun")
	end)
	local componentsToReplicate = self.ClonerManager:Flush()

	local mapScript = newMap:FindFirstChild("MapScript")
	if mapScript then
		self.MapScript = self.ClonerManager.Manager:AddComponent(mapScript, Binder)
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
	
	self.ClonerManager:ReplicateToClients(componentsToReplicate)

	self.ChangingMaps = false

	self.MapChanged:Fire(newMap)
	self.Client.CurrentMap:Set(newMap)
end

function MapService:_reconcileTeams(newNameToColor)
	local oldTeamMap = {}
	for _, team in CollectionService:GetTagged("FightingTeam") do
		oldTeamMap[team.Name] = {players = team:GetPlayers(), color = team.TeamColor}
	end

    local reconciledTeams, newTeamsMap, untrackedPlayers = reconcileTeams(
		CollectionService:GetTagged("FightingPlayer"), newNameToColor, oldTeamMap
	)

	for _, player in untrackedPlayers do
		player.Team = Teams.Spectators
	end

	local toRemove = {}
	for name in oldTeamMap do
		table.insert(toRemove, Teams:FindFirstChild(name))
	end

	local toAdd = {}
	for name, data in newTeamsMap do
		local newTeam = Instance.new("Team")
		newTeam.AutoAssignable = false
		CollectionService:AddTag(newTeam, "FightingTeam")
		CollectionService:AddTag(newTeam, "Map")

		newTeam.TeamColor = data.color
		newTeam.Name = name

		toAdd[name] = {
			players = data.players;
			team = newTeam;
		}
	end

	local reconciledRobloxTeams = {}
	for oldTeamName, newTeam in reconciledTeams do
		reconciledRobloxTeams[Teams:FindFirstChild(oldTeamName)] = toAdd[newTeam.name].team
	end

	for _, data in toAdd do
		data.team.Parent = Teams
		for _, player in data.players do
			player.Team = data.team
		end
	end

	for _, team in toRemove do
		team.Parent = nil
	end

	return reconciledRobloxTeams
end

return MapService