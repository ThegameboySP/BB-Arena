local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local e = Roact.createElement
local actions = RoduxFeatures.actions

local ProfileApp = require(script.Parent)

return function(target)
	local state = RoduxFeatures.reducer(nil, actions.userJoined(1))
	state = RoduxFeatures.reducer(state, actions.userJoined(2))
	state = RoduxFeatures.reducer(state, actions.playerDied(2, 1, GameEnum.DeathCause.Kill, "Superball", 71))

	local roactTree = e(ProfileApp, {
		players = {
			{
				displayName = "Delfino",
				name = "Thegameboy",
				image = "rbxthumb://type=AvatarHeadShot&id=351624&w=180&h=180",
				data = { stats = state.stats.alltimeStats[1], place = nil, timePlayed = 0, rank = GameEnum.Ranks.SPlus },
			},
			{
				displayName = "Bog",
				name = "Boy4u2",
				image = "rbxthumb://type=AvatarBust&id=34279992&w=180&h=180",
				data = { stats = state.stats.alltimeStats[1], place = 100, timePlayed = 0, rank = GameEnum.Ranks.D },
			},
			{
				displayName = "Spiderman",
				name = "ranoldinio2",
				image = "rbxthumb://type=AvatarBust&id=1951387&w=180&h=180",
				data = { stats = state.stats.alltimeStats[1], place = 53, timePlayed = 60, rank = GameEnum.Ranks.SPlus },
			},
		},
	})

	local tree = Roact.mount(roactTree, target)

	return function()
		Roact.unmount(tree)
	end
end
