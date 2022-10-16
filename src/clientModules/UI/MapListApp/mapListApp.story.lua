local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local e = Roact.createElement

local MapListApp = require(script.Parent)

local mapInfo = {}
for i = 1, 100 do
    mapInfo[i] = {
        ["teamSize"] = 2;
        ["size"] = i .. "x" .. 100 - i;
        ["neutralAllowed"] = true;
        ["supportsCTF"] = i % 2 == 0;
        ["supportsControlPoints"] = i % 2 == 1;
        ["creator"] = "Boy4u2, NewtonVolten2, unlucky ";
    }
end

return function(target)
    local store = Rodux.Store.new(RoduxFeatures.reducer, nil, { Rodux.thunkMiddleware })
    store:dispatch(RoduxFeatures.actions.setMapInfo(mapInfo))

	local tree
	local roactTree = e(MapListApp, {
		onClosed = function()
			Roact.unmount(tree)
		end;
        activeMap = 2;
	})
    
	roactTree = Roact.createElement(RoactRodux.StoreProvider, {
		store = store;
	}, {
		Main = roactTree
	})

	tree = Roact.mount(roactTree, target)

	return function()
		Roact.unmount(tree)
	end
end