local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Dictionary = Llama.Dictionary
local t = require(ReplicatedStorage.Packages.t)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Components = require(ReplicatedStorage.Common.Components)

local Gamemodes = ReplicatedStorage.Common.Gamemodes

local GamemodeService = {
    Name = "GamemodeService";
    Client = {
        CurrentGamemode = Root.remoteProperty(nil);
    };

    GamemodeStarted = Signal.new();
    GamemodeOver = Signal.new();

    CurrentGamemode = nil;
    gamemodeProcess = nil;
    binder = nil;
}

local gamemodeDefinition = t.strictInterface({
    stopOnMapChange = t.optional(t.boolean);
    hasMapProps = t.optional(t.boolean);
    minTeams = t.integer;
    friendlyName = t.string;
    nameId = t.string;
    config = t.table;
    stats = t.optional(t.table);

    cmdrConfig = t.table;
});

local function loadGamemodes(parent, callback)
    local gamemodes = {}

    for _, child in pairs(parent:GetChildren()) do
        callback(child)
        local gamemode = require(child)
        gamemodes[gamemode.definition.nameId] = gamemode
    end

    return gamemodes
end

function GamemodeService:OnInit()
    self.MapService = Root:GetService("MapService")
    self.StatService = Root:GetService("StatService")

    self.gamemodes = loadGamemodes(Gamemodes, function(module)
        local definition = require(module).definition
        local ok, err = gamemodeDefinition(definition)
        if not ok then
            error(("Gamemode %s definition error: %s"):format(module.Name, err))
        end

        definition.configChecker = t.strictInterface(definition.config)

        for name, data in pairs(definition.stats or {}) do
            local clonedData = table.clone(data)
            clonedData.domain = definition.nameId
            clonedData.showOnGamemode = data.show
            clonedData.name = name
            clonedData.show = false
            
            self.StatService:RegisterStat(clonedData)
        end
    end)

    self.MapService.MapChanging:Connect(function(map, _, oldTeamToNewTeam)
        if self.CurrentGamemode then
            local definition = self.CurrentGamemode.definition
            if definition.stopOnMapChange then
                self:StopGamemode()
                return
            end
    
            if not definition.nameId or self:_mapSupportsGamemode(map, definition) then
                self:_runGamemodeProtoypes(definition)
                self.gamemodeProcess:OnMapChanged(oldTeamToNewTeam)
            end
        end
    end)
end

function GamemodeService:SetGamemode(name, config)
    if self.CurrentGamemode and self.CurrentGamemode.definition.nameId == name then
        return false, string.format("%q is already set", name)
    end

    local gamemode = self.gamemodes[name] or error(("No gamemode %q"):format(name))
    local definition = gamemode.definition

    do
        local ok, err = self:_mapSupportsGamemode(self.MapService.CurrentMap, definition)
        if not ok then
            return false, err
        end
    end

    do
        local ok, err = self:_checkConfig(config, gamemode)
        if not ok then
            return false, err
        end
    end

    self:StopGamemode()
    self.CurrentGamemode = gamemode

    for _, registeredStat in pairs(self.StatService:GetRegisteredStatsByDomain(name)) do
        self.StatService:SetStatVisibility(registeredStat.name, registeredStat.showOnGamemode)
    end

    self:_runGamemodeProtoypes(definition)

    local binder = Instance.new("Folder")
    binder.Name = "Binder"
    binder.Parent = ReplicatedStorage
    self.binder = Components.Binder.new(binder)

    self.config = config
    self.gamemodeProcess = gamemode.server.new(self, self.binder)
    self.gamemodeProcess:OnInit(config, CollectionService:GetTagged("FightingTeam"))

    self.Client.CurrentGamemode:Set(definition.nameId)
    self.GamemodeStarted:Fire(definition)

    return true, string.format("Gamemode set to %q", name)
end

function GamemodeService:_mapSupportsGamemode(map, definition)
    if map == nil then
        return false, "There is no active map."
    end
    
    if definition.minTeams > #CollectionService:GetTagged("FightingTeam") then
        return false, string.format("%s needs at least %d teams to work", definition.friendlyName, definition.minTeams)
    end

    if definition.hasMapProps and not map:FindFirstChild(definition.nameId) then
        return false, string.format("Map does not support %s", definition.friendlyName)
    end

    return true
end

function GamemodeService:_runGamemodeProtoypes(definition)
    self.MapService.ClonerManager.Cloner:RunPrototypes(function(record)
        return record.parent.Name == definition.nameId
    end)
    local components = self.MapService.ClonerManager:Flush()

    task.spawn(function()
        if self.MapService.ChangingMaps then
            self.MapService.MapChanged:Wait()
        end

        self.MapService.ClonerManager:ReplicateToClients(components)
    end)
end

function GamemodeService:StopGamemode(completedSuccessfully)
    if self.gamemodeProcess then
        self.gamemodeProcess:Destroy()
        self.gamemodeProcess = nil
        
        local cloner = self.MapService.ClonerManager.Cloner
        local nameId = self.CurrentGamemode.definition.nameId
        local prototypes = cloner:GetPrototypes(function(record)
            return record.parent.Name == nameId
        end)

        for _, prototype in pairs(prototypes) do
            cloner:DespawnClone(cloner:GetCloneByPrototype(prototype))
        end

        self.CurrentGamemode = nil

        self.binder.Instance.Parent = nil
        self.binder:Destroy()
        self.binder = nil

        self.Client.CurrentGamemode:Set(nil)

        self.GamemodeOver:Fire({cancelled = not completedSuccessfully})

        for _, registeredStat in pairs(self.StatService:GetRegisteredStatsByDomain(nameId)) do
            for _, player in pairs(Players:GetPlayers()) do
                self.StatService.Stats:Set(player.UserId, registeredStat.name, registeredStat.default)
            end

            self.StatService:SetStatVisibility(registeredStat.name, false)
        end

        return true
    end

    return false
end

function GamemodeService:_checkConfig(config, gamemode)
    return gamemode.definition.configChecker(config)
end

function GamemodeService:FireGamemodeEvent(name, value)
    if self.gamemodeProcess then
        local methodName = "On" .. name:sub(1, 1):upper() .. name:sub(2, -1)
        self.gamemodeProcess[methodName](self.gamemodeProcess, value)
        
        return true
    end

    return false
end

function GamemodeService:SetConfig(delta)
    if self.gamemodeProcess then
        local resolved = Dictionary.merge(self.config, delta)
        local ok, err = self:_checkConfig(resolved, self.CurrentGamemode)
        if not ok then
            return false, err
        end

        self.config = resolved
        self.gamemodeProcess:OnConfigChanged(resolved)

        return true
    end

    return false
end

function GamemodeService:GetManager()
    return self.MapService.ClonerManager.Manager
end

function GamemodeService:SayEvent(msg, options)
    Root.hint(msg, options)
end

function GamemodeService:AnnounceEvent(msg, options)
    Root.notification(msg, options)
end

return GamemodeService