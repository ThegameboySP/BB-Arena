local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Promise = require(ReplicatedStorage.Packages.Promise)

local e = Roact.createElement

local ThemeController = require(script.Parent.ThemeController)
local profileMainWidget = require(script.profileMainWidget)

local Profile = Roact.Component:extend("Profile")

function Profile:render()
	return e(ThemeController, {}, {
		Profile = e(profileMainWidget, self.props),
	})
end

Profile = RoactRodux.connect(function(state, props)
	local players = {}

	local hasFetched = state.leaderboard.hasFetched

	for userId, userInfo in state.users.activeUsers do
		players[userId] = {
			name = userInfo.name,
			displayName = userInfo.displayName,
			userId = userId,
			image = Promise.try(function()
				return Players:GetUserThumbnailAsync(
					userId,
					Enum.ThumbnailType.AvatarBust,
					Enum.ThumbnailSize.Size100x100
				)
			end),
			data = {
				stats = state.stats.alltimeStats[userId],
				place = if hasFetched then state.leaderboard.placeByUserId[userId] else "?",
				timePlayed = userInfo.timePlayed + (Workspace:GetServerTimeNow() - userInfo.joinedTimestamp),
				rank = nil,
			},
		}
	end

	return Llama.Dictionary.merge(props, {
		players = players,
		localUserId = props.localUserId,
	})
end)(Profile)

return Profile
