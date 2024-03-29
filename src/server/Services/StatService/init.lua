local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local EventBus = require(ReplicatedStorage.Common.EventBus)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

local StatService = {
	Name = "StatService",
}

function StatService:OnInit()
	EventBus.playerDied:Connect(function(victim, info)
		if victim.Team ~= Teams.Spectators then
			local distance = 0

			if info.victimCharacter and info.killerCharacter then
				local victimHead = info.victimCharacter:FindFirstChild("Head")
				local killerHead = info.killerCharacter:FindFirstChild("Head")

				if victimHead and killerHead then
					distance = (victimHead.Position - killerHead.Position).Magnitude
				end
			end

			self.Root.Store:dispatch(
				actions.playerDied(
					victim.UserId,
					info.killer and info.killer.UserId,
					info.cause,
					info.projectileType,
					distance
				)
			)
		end
	end)
end

function StatService:GetRegisteredStats()
	return self.Root.Store:getState().stats.registeredStats
end

function StatService:SetStatVisual(userId, name, value)
	self.Root.Store:dispatch(actions.setStatVisual(userId, name, value))
end

function StatService:IncrementStat(userId, name, amount)
	self.Root.Store:dispatch(actions.incrementStat(userId, name, amount))
end

return StatService
