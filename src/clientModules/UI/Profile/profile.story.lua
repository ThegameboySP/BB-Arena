local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local e = Roact.createElement
local actions = RoduxFeatures.actions

local ProfileApp = require(script.Parent)

return function(target)
	local store = Rodux.Store.new(RoduxFeatures.reducer)
	store:dispatch(actions.userJoined(351624, "mah", "name"))
	store:dispatch(actions.userJoined(201, "walrus", "itus"))
	store:dispatch(actions.userJoined(202, "mr", "magic"))
	store:dispatch(actions.userJoined(203, "louie", "louie"))
	store:dispatch(actions.userJoined(204, "magnificent", "cactus"))
	store:dispatch(actions.userJoined(205, "Supercalifragilisticexpialidocious", "Supercalifragilisticexpialidocious"))
	store:dispatch(actions.userJoined(206, "sugar", "sugar"))
	store:dispatch(
		actions.userJoined(207, "according to all known laws of aviation", "according to all known laws of aviation")
	)
	store:dispatch(actions.userJoined(208, "a bee", "should not be able to fly"))
	store:dispatch(actions.playerDied(201, 351624, GameEnum.DeathCause.Kill, "Superball", 71))
	store:dispatch(actions.leaderboardFetched({
		{ userId = 351624, KOs = 20, WOs = 10 },
	}))

	local roactTree = e(ProfileApp, {
		localUserId = 351624,
	})

	roactTree = Roact.createElement(RoactRodux.StoreProvider, {
		store = store,
	}, {
		Main = roactTree,
	})

	local tree = Roact.mount(roactTree, target)

	return function()
		Roact.unmount(tree)
	end
end
