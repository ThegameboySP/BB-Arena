local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local Binder = require(ReplicatedStorage.Common.Components.Binder)
local ClonerManager = require(ReplicatedStorage.Common.Component).ClonerManager
local Definitions = require(ReplicatedStorage.Common.Definitions)
local MatterComponents = require(ReplicatedStorage.Common.MatterComponents)

local reconcileTeams = require(script.reconcileTeams)

local Components = require(ReplicatedStorage.Common.Components)

local MapService = {
	Name = "MapService";
	Client = {
		MapChanging = Root.Services.remoteEvent();
		MapChanged = Root.Services.remoteEvent();
		PlayerStreamedMap = Root.Services.remoteEvent();
		CurrentMap = Root.Services.remoteProperty(nil);
	};
	Priority = 1;

	Maps = ServerStorage.Maps;
	LightingSaves = ServerStorage.Plugin_LightingSaves;
	mapParent = Workspace.MapRoot;

	MapChanging = Signal.new();
	MapChanged = Signal.new();

	CurrentMap = nil;
	ChangingMaps = false;
	MapScript = nil;

	ClonerManager = ClonerManager.new("MapComponents");

	_lastRegenTimes = {};
}

function MapService:OnInit()
	for _, child in pairs(self.mapParent:GetChildren()) do
		if CollectionService:HasTag(child, "Map") then
			-- The client can sometimes log in fast enough for the map to be automatically replicated.
			-- This can mess up prototypes since they're deparented when invisible to the client, then when
			-- it comes into scope again the client tries to locally run them.
			-- So we clone any maps that were under Workspace. Not pretty.
			child:Clone().Parent = self.Maps
			child.Parent = nil
		end
	end

    local mapInfo = {}
	for _, map in pairs(self.Maps:GetChildren()) do
		local ok, err = Definitions.map(map)
		if not ok then
			warn("[MapService]", string.format("Map %q is not valid: %s. Removing it.", map.Name, err))
			map.Parent = nil
		end

		mapInfo[map.Name] = require(map:FindFirstChild("Meta"))
	end

	self.Root.globals.mapInfo:Set(table.freeze(mapInfo))

	self.LightingSaves.Name = "LightingSaves"
	self.LightingSaves.Parent = ReplicatedStorage

	RunService.Heartbeat:Connect(function()
		if not self.CurrentMap then
			return
		end

		local prototypes = {}
		local clones = {}

		local currentTime = os.clock()
		for _, component in self.ClonerManager.Manager:GetComponents(Components.RegenGroup) do
			local prototype = self.ClonerManager.Cloner:GetPrototypeByClone(component.Instance)

			local lastTime = self._lastRegenTimes[prototype]
			if lastTime == nil then
				self._lastRegenTimes[prototype] = currentTime
				continue
			end

			if (currentTime - lastTime) >= component.Config.Time then
				table.insert(clones, component.Instance)
				table.insert(prototypes, prototype)
			end
		end

		if clones[1] then
			self:_regen(clones, prototypes)
		end
	end)

	self.Client.PlayerStreamedMap:Connect(function(player)
		CollectionService:RemoveTag(player, "PlayerStreamingMap")
	end)
end

function MapService:OnStart()
	for _, component in Components do
		self:RegisterComponent(component)
	end
end

function MapService:RegisterComponent(class)
	if class.realm ~= "client" then
		self.ClonerManager:Register(class)
	end
end

function MapService:_regen(clones, prototypes)
	for _, clone in clones do
		self.ClonerManager.Cloner:DespawnClone(clone)
	end

	self.ClonerManager.Cloner:RunPrototypes(prototypes)

	local components = self.ClonerManager:Flush()
	self.ClonerManager:ReplicateToClients(components)

	local currentTime = os.clock()
	for _, prototype in prototypes do
		self._lastRegenTimes[prototype] = currentTime
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

	self:_regen(clones, prototypes)
end

function MapService:ChangeMap(mapName)
	if self.CurrentMap and self.CurrentMap.Name == mapName then
        return false, ("Already playing on map: %q"):format(mapName)
    end

	local newMap = self.Maps:FindFirstChild(mapName)
	if newMap == nil then
		return false, ("No map name called: %q"):format(mapName)
	end

	local meta = require(newMap:FindFirstChild("Meta"))

	self.ChangingMaps = true
	self.MapScript = nil

	-- Separate from Clear so server can replicate deparenting clones before map change
	-- (or else automatic replication won't know to clear the old clones. Only clearing has the same
	-- effect but with prototypes, since clearing also reparents the prototypes)
	if self.ClonerManager.Cloner then
		self.ClonerManager.Cloner:DespawnAll()
	end

	local oldMap = self.CurrentMap
	if oldMap then
		oldMap.Parent = self.Maps
	end

	-- Should reconcile teams before components run.
	local oldTeamToNewTeam = self:_reconcileTeams(meta.Teams)

	table.clear(self._lastRegenTimes)
	self.ClonerManager:Clear()
	self.ClonerManager:ServerInit(newMap)
	self.ClonerManager.Cloner:RunPrototypes(function(record)
		local currentRecord = record
		while currentRecord do
			if
				currentRecord.prototype:GetAttribute("Prototype_DisableRun")
				or currentRecord.parent:GetAttribute("Prototype_DisableRun")
			then
				return false
			end

			currentRecord = currentRecord.ancestorPrototype
		end

		return true
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
	self.MapChanging:Fire(newMap, oldMap, oldTeamToNewTeam)
	self.Client.MapChanging:FireAllClients(newMap.Name, oldMap and oldMap.Name or nil)

	newMap.Parent = self.mapParent

	if repFirst then
		repFirst.Parent = newMap
	end

	for _, player in pairs(CollectionService:GetTagged("ParticipatingPlayer")) do
        task.spawn(player.LoadCharacter, player)
	end

	for _, player in Players:GetPlayers() do
		CollectionService:AddTag(player, "PlayerStreamingMap")
	end

	self.ClonerManager:ReplicateToClients(componentsToReplicate)

	self.ChangingMaps = false

	self.Root.Store:dispatch(RoduxFeatures.actions.mapChanged(mapName))
	self.MapChanged:Fire(newMap)
	self.Client.CurrentMap:Set(newMap)
end

function MapService:GetMaps()
	local children = self.Maps:GetChildren()
	if self.CurrentMap then
		table.insert(children, self.CurrentMap)
	end

	return children
end

function MapService:_reconcileTeams(newNameToColor)
	local TeamService = self.Root:GetService("TeamService")

	local oldTeamMap = {}
	local participatingPlayers = {}

	for teamId, team in self.Root.world:query(MatterComponents.Team) do
		if team.participating and not team.fromMap then
			local players = TeamService:getPlayersFromTeam(teamId)
			for _, playerId in players do
				table.insert(participatingPlayers, playerId)
			end

			oldTeamMap[team.name] = {
				players = players;
				color = team.color;
				id = teamId;
			}
		end
	end

    local reconciledTeams, newTeamsMap, untrackedPlayers = reconcileTeams(
		participatingPlayers, newNameToColor, oldTeamMap
	)

	-- Team players that are not under any team to Spectators.
	for _, id in untrackedPlayers do
		self.Root.world:insert(id, self.Root.world:get(id, Components.Player):patch({
			teamId = self.Root:getIdFromInstance(Teams.Spectators);
		}))
	end

	-- Spawn/replace new teams over top old ones.
	for name, team in newTeamsMap do
		local newTeamComponent = MatterComponents.Team({
			name = name;
			participating = true;
			enableTools = true;
			fromMap = true;
			color = team.color;
		})

		if team.replacingTeam then
			self.Root.world:replace(team.replacingTeam.id, newTeamComponent)

			for _, playerId in team.players do
				self.Root.world:get(playerId, MatterComponents.Player):patch({
					teamId = team.id;
				})
			end
		else
			self.Root.world:spawn(newTeamComponent)
		end
	end

	-- Despawn old teams that have no corresponding new teams.
	for oldTeamName, oldTeam in oldTeamMap do
		if not reconciledTeams[oldTeamName] then
			self.Root.world:despawn(oldTeam.id)
		end
	end

	return reconciledTeams
end

return MapService