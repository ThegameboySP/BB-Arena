local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Gamemodes = ReplicatedStorage.Common.Gamemodes

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local GamemodeBinder = require(ReplicatedStorage.Common.Components.GamemodeBinder)

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

    local gamemodeBinder = ReplicatedStorage:FindFirstChild("GamemodeBinder")
    if not gamemodeBinder then
        error("Could not find gamemode binder")
    end

    self.clonerManager:Flush()
    self.binder = self.clonerManager.Manager:AddComponent(gamemodeBinder, GamemodeBinder)

    local gamemode = require(Gamemodes:FindFirstChild(gamemodeName))
    self.client = gamemode.client.new(self.binder)
    self.client:OnInit(CollectionService:GetTagged("FightingTeam"))
end

function GamemodeController:onGamemodeEnded()
    if self.client then
        self.client:Destroy()
        self.client = nil
        self.binder:Destroy()
        self.binder = nil
    end
end

function GamemodeController:onMapChanged()
    
end

return GamemodeController