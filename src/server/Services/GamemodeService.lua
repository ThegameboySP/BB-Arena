local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Dictionary = Llama.Dictionary
local t = require(ReplicatedStorage.Packages.t)
local Binder = require(ReplicatedStorage.Common.Components.Binder)

local Gamemodes = ReplicatedStorage.Common.Gamemodes

local GamemodeService = Knit.CreateService({
    Name = "GamemodeService";
    Client = {
        CurrentGamemode = Knit.CreateProperty(nil);
    };

    CurrentGamemode = nil;
    gamemodeProcess = nil;
    binder = nil;
})

local gamemodeDefinition = t.strictInterface({
    stopOnMapChange = t.optional(t.boolean);
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

function GamemodeService:KnitInit()
    self.MapService = Knit.GetService("MapService")

    self.gamemodes = loadGamemodes(Gamemodes, function(module)
        local ok, err = gamemodeDefinition(require(module).definition)
        if not ok then
            error(("Gamemode %s definition error: %s"):format(module.Name, err))
        end
    end)

    self.MapService.PreMapChanged:Connect(function(map, _, oldTeamToNewTeam)
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
    self.commonStore = Knit.GetService("CmdrService").Cmdr.Registry:GetStore("Common")
    self.commonStore.currentGamemodeName = name

    self:_runGamemodeProtoypes(definition)

    local binder = Instance.new("Folder")
    binder.Name = "Binder"
    binder.Parent = ReplicatedStorage
    self.binder = Binder.new(binder)

    self.gamemodeProcess = gamemode.server.new(self, self.binder)
    self.gamemodeProcess:OnInit(config, CollectionService:GetTagged("FightingTeam"))

    self.Client.CurrentGamemode:Set(definition.nameId)

    return true, string.format("Gamemode set to %q", name)
end

function GamemodeService:_mapSupportsGamemode(map, definition)
    if definition.minTeams > #CollectionService:GetTagged("FightingTeam") then
        return false, string.format("%s needs at least %d teams to work", definition.friendlyName, definition.minTeams)
    end

    if not map:FindFirstChild(definition.nameId) then
        return false, string.format("Map does not support %s", definition.friendlyName)
    end

    return true
end

function GamemodeService:_runGamemodeProtoypes(definition)
    self.MapService._clonerManager.Cloner:RunPrototypes(function(record)
        return record.parent.Name == definition.nameId
    end)
    local components = self.MapService._clonerManager:Flush()

    task.spawn(function()
        if self.MapService.ChangingMaps then
            self.MapService.MapChanged:Wait()
        end

        self.MapService._clonerManager:ReplicateToClients(components)
    end)
end

function GamemodeService:StopGamemode()
    if self.gamemodeProcess then
        self.gamemodeProcess:Destroy()
        self.gamemodeProcess = nil
        
        local cloner = self.MapService._clonerManager.Cloner
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

        return true
    end

    return false
end

function GamemodeService:_checkConfig(config, gamemode)
    local definition = gamemode.definition

    for k, v in pairs(config) do
        if not definition.config[k] then
            return false, "Unexpected key " .. k
        end

        local ok, err = definition.config[k](v)
        if not ok then
            return false, err
        end
    end

    return true
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

        self.gamemodeProcess:OnConfigChanged(resolved)

        return true
    end

    return false
end

function GamemodeService:GetManager()
    return self.MapService._clonerManager.Manager
end

function GamemodeService:SayEvent(msg, color)
    Knit.hint(msg, color)
end

function GamemodeService:AnnounceEvent(msg, color)
    Knit.notification(msg, color)
end

return GamemodeService