local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Promise = require(ReplicatedStorage.Packages.Promise)

local e = Roact.createElement

local ThemeController = require(script.Parent.ThemeController)
local leaderboardWidget = require(script.leaderboardWidget)

local Leaderboard = Roact.Component:extend("Leaderboard")

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

Leaderboard = RoactRodux.connect(function(state, props)
	local userInfo = {}

	for index, info in state.leaderboard.users do
		table.insert(userInfo, {
			["User"] = info.name,
			["KOs"] = withCommas(info.KOs),
			["WOs"] = withCommas(info.WOs),
			["KDR"] = string.format("%.1f", if info.WOs == 0 then info.KOs else info.KOs / info.WOs),
			["image"] = Promise.try(function()
				return Players:GetUserThumbnailAsync(
					info.userId,
					Enum.ThumbnailType.AvatarBust,
					Enum.ThumbnailSize.Size100x100
				)
			end),
			index = index,
		})
	end

	return Llama.Dictionary.merge(props, {
		userInfo = userInfo,
	})
end)(Leaderboard)

return Leaderboard
