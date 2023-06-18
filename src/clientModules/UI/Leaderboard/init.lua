local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Promise = require(ReplicatedStorage.Packages.Promise)

local e = Roact.createElement

local ThemeController = require(script.Parent.ThemeController)
local leaderboardWidget = require(script.leaderboardWidget)

local Leaderboard = Roact.PureComponent:extend("Leaderboard")

function Leaderboard:render()
	return e(ThemeController, {}, {
		Leaderboard = e(leaderboardWidget, self.props),
	})
end

local function withCommas(number)
	local parts = string.split(tostring(math.floor(number)), "")

	local i = #parts - 2
	while i > 1 do
		table.insert(parts, i, ",")
		i -= 3
	end

	return table.concat(parts)
end

Leaderboard = RoactRodux.connect(function()
	local lastUsers = nil
	local cachedUserInfo = nil

	return function(state, props)
		if cachedUserInfo and lastUsers == state.leaderboard.users then
			return Llama.Dictionary.merge(props, {
				userInfo = cachedUserInfo,
			})
		end

		local userInfo = {}

		for index, info in state.leaderboard.users do
			local KDR = if info.WOs == 0 then info.KOs else info.KOs / info.WOs

			table.insert(userInfo, {
				User = info.name,
				KOs = { original = info.KOs, string = withCommas(info.KOs) },
				WOs = { original = info.WOs, string = withCommas(info.WOs) },
				KDR = { original = KDR, string = string.format("%.1f", KDR) },
				image = Promise.try(function()
					return Players:GetUserThumbnailAsync(
						info.userId,
						Enum.ThumbnailType.AvatarBust,
						Enum.ThumbnailSize.Size100x100
					)
				end),
				index = index,
			})
		end

		cachedUserInfo = userInfo
		lastUsers = state.leaderboard.users

		return Llama.Dictionary.merge(props, {
			userInfo = userInfo,
		})
	end
end)(Leaderboard)

return Leaderboard
