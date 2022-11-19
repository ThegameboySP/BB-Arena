local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Signal = require(ReplicatedStorage.Packages.Signal)
local EventBus = require(ReplicatedStorage.Common.EventBus)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

local StatService = {
    Name = "StatService";

    -- For keeping track of stat scopes.
    StatIncremented = Signal.new();
}

function StatService:OnInit()
    EventBus.playerDied:Connect(function(victim, info)
        if victim.Team ~= Teams.Spectators then
            self.Root.Store:dispatch(actions.playerDied(
                victim.UserId,
                info.killer and info.killer.UserId,
                info.cause
            ))
        end
    end)
end

function StatService:GetRegisteredStats()
    return self.Root.Store:getState().stats.registeredStats
end

-- TODO
-- function StatService:NewStatScope()

-- end

function StatService:SetStatVisual(userId, name, value)
    self.Root.Store:dispatch(actions.setStatVisual(userId, name, value))
end

function StatService:IncrementStat(userId, name, amount)
    self.Root.Store:dispatch(actions.incrementStat(userId, name, amount))
    self.StatIncremented:Fire(userId, name, amount)
end

return StatService