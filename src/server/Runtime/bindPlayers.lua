local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Promise = require(ReplicatedStorage.Packages.Promise)

-- Calls all top-level :OnPlayerAdded/Removing methods/signals in the right
-- order to prevent race conditions.
local function bindPlayers(root)
	local GatekeepingService = root:GetService("GatekeepingService")
	local GameDataStoreService = root:GetService("GameDataStoreService")
	local RoduxService = root:GetService("RoduxService")

	local function onPlayerAdded(player)
		if GatekeepingService:OnPlayerAdded(player) then
			RoduxService:OnPlayerAdded(player)
			-- root.PlayerAdded:Fire(player)

			Promise.all({
				Promise.delay(0.2), -- a quick hack for legacy PlayerAdded connections
				GameDataStoreService:OnPlayerAdded(player),
			}):finally(function()
				if player.Parent then
					-- root.PlayerLoaded:Fire(player)
					player:SetAttribute("Initialized", true)
				end
			end)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		-- root.PlayerRemoving:Fire(player)

		GameDataStoreService:OnPlayerRemoving(player)
		RoduxService:OnPlayerRemoving(player)
		-- root.PlayerRemoved:Fire(player)
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return bindPlayers
