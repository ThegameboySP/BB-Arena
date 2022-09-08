local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local e = Roact.createElement

local app = require(script.Parent)

return function(target)
	local tree
	local roactTree = e(app, {
		onClosed = function()
			Roact.unmount(tree)
		end;
	})

	roactTree = Roact.createElement(RoactRodux.StoreProvider, {
		store = Rodux.Store.new(RoduxFeatures.reducer, nil, { Rodux.thunkMiddleware });
	}, {
		Main = roactTree
	})

	tree = Roact.mount(roactTree, target)

	return function()
		Roact.unmount(tree)
	end
end