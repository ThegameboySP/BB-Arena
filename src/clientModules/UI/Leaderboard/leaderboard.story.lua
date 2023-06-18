local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local mountLeaderboards = require(ReplicatedStorage.ClientModules.Scripts.mountLeaderboards)

local e = Roact.createElement

local app = require(script.Parent)

return function(target)
	local tree
	local roactTree = e(app)

	local store = Rodux.Store.new(RoduxFeatures.reducer)
	local data = {
		{ userId = 351624, name = "Delfino(@Thegameboy)", KOs = 33111113, WOs = 33111113 },
		{ userId = 351624, name = "Bog(@Boy4u2)", KOs = 31337, WOs = 100 },
		{ userId = 351624, name = "Bog(@Boy4u2)LONGLONGLONGLONGLONGLONG", KOs = 31337, WOs = 100 },
		{ userId = 1, name = "SomeGuy", KOs = 2, WOs = 2 },
		{ userId = 1, name = "ranoldinio2", KOs = 2, WOs = 2 },
		{ userId = 1337, name = "Walrus", KOs = 1, WOs = 2 },
		{ userId = 1337, name = "Walrus2", KOs = 1, WOs = 2 },
		{ userId = 1, name = "SomeGuy2", KOs = 2, WOs = 2 },
		{ userId = 1, name = "ranoldinio22", KOs = 2, WOs = 2 },
		{ userId = 1337, name = "Walrus2", KOs = 1, WOs = 2 },
		{ userId = 1337, name = "Walrus22", KOs = 1, WOs = 2 },
		{ userId = 351624, name = "Delfino(@Thegameboy)2", KOs = 33111113, WOs = 33111113 },
		{ userId = 351624, name = "Bog(@Boy4u2)2", KOs = 31337, WOs = 100 },
		{ userId = 1, name = "SomeGuy2", KOs = 2, WOs = 2 },
		{ userId = 1, name = "ranoldinio22", KOs = 2, WOs = 2 },
		{ userId = 1337, name = "Walrus2", KOs = 1, WOs = 2 },
		{ userId = 1337, name = "Walrus22", KOs = 1, WOs = 2 },
		{ userId = 1, name = "SomeGuy22", KOs = 2, WOs = 2 },
		{ userId = 1, name = "ranoldinio222", KOs = 2, WOs = 2 },
		{ userId = 1337, name = "Walrus22", KOs = 1, WOs = 2 },
		{ userId = 1337, name = "Walrus222", KOs = 1, WOs = 2 },
	}

	table.sort(data, function(a, b)
		return a.KOs > b.KOs
	end)

	store:dispatch(RoduxFeatures.actions.leaderboardFetched(data))

	roactTree = Roact.createElement(RoactRodux.StoreProvider, {
		store = store,
	}, {
		Main = roactTree,
	})

	tree = Roact.mount(roactTree, target)

	local undoMount = mountLeaderboards(store)
	return function()
		Roact.unmount(tree)
		undoMount()
	end
end
