local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)
local t = require(ReplicatedStorage.Packages.t)

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
		MapInfo = Knit.CreateProperty(nil)
	};
	
	Maps = ServerStorage.Maps;
	LightingSaves = ServerStorage.Plugin_LightingSaves;
	startingMapName = ReplicatedStorage.Configuration:GetAttribute("StartingMapName");
	mapParent = workspace;

	PreMapChanged = Signal.new();
	MapChanged = Signal.new();
	
	CurrentMap = nil;
	
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

	if self.startingMapName then
	    self:ChangeMap(self.startingMapName)
    end

	RunService.Heartbeat:Connect(function()
		for _, player in pairs(Players:GetPlayers()) do
			if self._teamMap[player.Team] then
				-- TODO: is hasTag necessary? would adding/removing otherwise replicate every frame?
				if CollectionService:HasTag(player, "FightingPlayer") then
					CollectionService:AddTag(player, "FightingPlayer")
				else
					CollectionService:RemoveTag(player, "FightingPlayer")
				end
			end
		end
	end)
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
	
	local repFirst = newMap:FindFirstChild("ReplicateFirst")
	if repFirst then
		repFirst.Parent = self.mapParent
	end

    local oldMap = self.CurrentMap
    if oldMap then
		oldMap.Parent = self.Maps
	end

	self.CurrentMap = newMap
	self.PreMapChanged:Fire(newMap, oldMap)
	self.Client.PreMapChanged:FireAll(newMap.Name, oldMap and oldMap.Name or nil)

    self:_reconcileTeams(meta.Teams)
	self._teamMap = meta.Teams
	newMap.Parent = self.mapParent

	if repFirst then
		repFirst.Parent = newMap
	end
	
	for _, player in pairs(CollectionService:GetTagged("FightingPlayer")) do
        task.spawn(player.LoadCharacter, player)
	end
	
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
    local toSetToTeams = {}
	local newTeams = {}
	
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
				toSetToTeams[newTeam] = players
				newTeamIndex += 1
			end
		elseif existingTeam and not newTeam then
			for _, player in pairs(existingTeam:GetPlayers()) do
				player.Team = Teams.Spectators
				player:LoadCharacter()
			end
		end
		
		if existingTeam then
			existingTeam:Destroy()
		end
	end
	
	for _, newTeam in pairs(newTeams) do
		newTeam.Parent = Teams
	end
	
	for newTeam, players in pairs(toSetToTeams) do
		for _, player in pairs(players) do
			player.Team = newTeam
		end
	end
end

return MapService