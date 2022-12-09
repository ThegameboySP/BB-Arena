local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Effects = require(ReplicatedStorage.Common.Utils.Effects)

local function spectatorsCantCollide()
	Effects.call(
		Teams.Spectators,
		Effects.pipe({
			Effects.instance("GetPlayers", "PlayerAdded", "PlayerRemoved"),
			Effects.character,

			function(character)
				local parts = {}
				for _, descendant in pairs(character:GetDescendants()) do
					if descendant:IsA("BasePart") and descendant.CanCollide then
						table.insert(parts, descendant)
					end
				end

				local con = RunService.Heartbeat:Connect(function()
					for _, part in pairs(parts) do
						PhysicsService:SetPartCollisionGroup(part, "Spectators")
					end
				end)

				return function()
					con:Disconnect()

					for _, part in pairs(parts) do
						PhysicsService:SetPartCollisionGroup(part, "PlayerParts")
					end
				end
			end,
		})
	)
end

return spectatorsCantCollide
