local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Effects = require(ReplicatedStorage.Common.Utils.Effects)
local Dictionary = Llama.Dictionary

local MIN_FETCH_TIME = 10

local function givePlayerAppearanceServer(root)
	local PlayerAppearances = Instance.new("Folder")
	PlayerAppearances.Name = "PlayerAppearances"
	PlayerAppearances.Parent = ReplicatedStorage

	local NewPlayerAppearance = root:getRemoteEvent("NewPlayerAppearance")

	local userInfos = {}
	local lastFetchedAppearances = {}

	local function onSpawning(player)
		local userId = player.UserId
		if (os.clock() - (lastFetchedAppearances[userId] or 0)) < MIN_FETCH_TIME then
			return
		end

		local info
		pcall(function()
			info = Players:GetCharacterAppearanceInfoAsync(userId)
		end)

		if not info then
			return
		end

		lastFetchedAppearances[userId] = os.clock()

		if not userInfos[userId] or not Dictionary.equalsDeep(info, userInfos[userId]) then
			local appearanceModel
			pcall(function()
				appearanceModel = Players:GetCharacterAppearanceAsync(userId)
			end)

			if not appearanceModel then
				return
			end

			userInfos[userId] = info

			local oldModel = PlayerAppearances:FindFirstChild(tostring(userId))
			if oldModel then
				oldModel.Parent = nil
			end

			appearanceModel.Name = tostring(userId)
			appearanceModel.Parent = PlayerAppearances

			NewPlayerAppearance:FireAllClients(userId)
		end
	end

	Effects.call(
		Players,
		Effects.pipe({
			Effects.children,
			Effects.character,
			function(character)
				local player = Players:GetPlayerFromCharacter(character)
				onSpawning(player)

				local humanoid = character:FindFirstChild("Humanoid")
				local connection = humanoid.StateChanged:Connect(function(_, newState)
					if newState == Enum.HumanoidStateType.Dead then
						onSpawning(player)
					end
				end)

				return function()
					connection:Disconnect()
					onSpawning(player)
				end
			end,
		})
	)
end

return givePlayerAppearanceServer
