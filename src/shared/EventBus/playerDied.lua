local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Effects = require(ReplicatedStorage.Common.Utils.Effects)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)

return function(EventBus)
	local playerDied = EventBus.playerDied
	local trackingPlayers = {}

	function EventBus:GetPlayerDiedSignal(player)
		if trackingPlayers[player] then
			return trackingPlayers[player]
		end

		trackingPlayers[player] = Signal.new()

		return trackingPlayers[player]
	end

	Players.PlayerRemoving:Connect(function(player)
		if trackingPlayers[player] then
			trackingPlayers[player]:Destroy()
			trackingPlayers[player] = nil
		end
	end)

	Effects.call(
		Players,
		Effects.pipe({
			Effects.instance("GetPlayers", "PlayerAdded", "PlayerRemoving"),
			Effects.character,
			function(character)
				local humanoid = character:FindFirstChild("Humanoid")

				local con = humanoid.StateChanged:Connect(function(_, new)
					if new == Enum.HumanoidStateType.Dead then
						local player = Players:GetPlayerFromCharacter(character)
							or Players:FindFirstChild(character.Name)
						if not player then
							return
						end

						local creatorValue = humanoid:FindFirstChild("creator")
						local creatorCharacter

						if creatorValue then
							local folderRef = creatorValue:FindFirstChild("FolderRef")
							local folder = folderRef and folderRef.Value

							if folder then
								local characterRef = folder:FindFirstChild("Character")
								if characterRef then
									creatorCharacter = characterRef.Value
								end
							end
						end

						local creator = creatorValue and creatorValue.Value

						if trackingPlayers[player] then
							trackingPlayers[player]:Fire(creator)
						end

						playerDied:Fire(player, {
							victimCharacter = character,
							killer = creator,
							cause = humanoid:GetAttribute("DeathCause"),
							weaponImageId = creatorValue and creatorValue:GetAttribute("WeaponImageId"),
							projectileType = creatorValue and creatorValue:GetAttribute("ProjectileType"),
							killerCharacter = creatorCharacter,
						})
					end
				end)

				return function()
					con:Disconnect()
				end
			end,
		})
	)
end
