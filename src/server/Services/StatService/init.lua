local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Root = require(ReplicatedStorage.Common.Root)
local EventBus = require(ReplicatedStorage.Common.EventBus)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

local StatService = {
    Name = "StatService";

    -- For keeping track of stat scopes.
    StatIncremented = Signal.new();
}

function StatService:OnInit()
    EventBus.playerDied:Connect(function(victim, killer)
        if victim.Team ~= Teams.Spectators then
            self:IncrementStat(victim.UserId, "WOs", 1)

            if killer and killer ~= victim then
                self:IncrementStat(killer.UserId, "KOs", 1)
            end
        end
    end)
end

function StatService:GetRegisteredStats()
    return Root.Store:getState().stats.registeredStats
end

-- TODO
-- function StatService:NewStatScope()

-- end

function StatService:SetStatVisual(userId, name, value)
    Root.Store:dispatch(actions.setStatVisual(userId, name, value))
end

function StatService:IncrementStat(userId, name, amount)
    Root.Store:dispatch(actions.incrementStat(userId, name, amount))
    self.StatIncremented:Fire(userId, name, amount)
end

return StatService