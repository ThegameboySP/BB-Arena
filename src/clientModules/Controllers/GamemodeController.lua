local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Gamemodes = ReplicatedStorage.Common.Gamemodes

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Binder = require(ReplicatedStorage.Common.Components.Binder)

local GamemodeController = Knit.CreateController({
	Name = "GamemodeController";
    binder = nil;
    client = nil;
})

function GamemodeController:KnitStart()
    self.commonStore = Knit.GetController("CmdrController").Cmdr.Registry:GetStore("Common")
    self.clonerManager = Knit.GetController("MapController")._clonerManager
end

function GamemodeController:onGamemodeStarted(gamemodeName)
    self.commonStore.currentGamemodeName = gamemodeName
    self.gamemodeName = gamemodeName

    local binder = ReplicatedStorage:FindFirstChild("Binder")
    if not binder then
        error("Could not find gamemode binder")
    end

    -- Flush so queued gamemode components can run now.
    self.clonerManager:Flush()
    
    self.binder = Binder.new(binder)

    self:_startGamemodeClient(self.binder, gamemodeName)
end

function GamemodeController:_startGamemodeClient(binder, gamemodeName)
    if self.client then
        self.client:Destroy()
        self.client = nil
    end

    local gamemode = require(Gamemodes:FindFirstChild(gamemodeName))
    self.client = gamemode.client.new(binder)
    self.client:OnInit(CollectionService:GetTagged("FightingTeam"))
end

function GamemodeController:onGamemodeEnded()
    if self.client then
        self.client:Destroy()
        self.client = nil
        self.binder:Destroy()
        self.binder = nil

        self.gamemodeName = nil
    end
end

function GamemodeController:onMapChanged()
    if self.gamemodeName then
        self:_startGamemodeClient(self.binder, self.gamemodeName)
    end
end

return GamemodeController