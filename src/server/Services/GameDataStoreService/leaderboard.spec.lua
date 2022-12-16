local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockDataStoreService = require(ServerScriptService.Packages.MockDataStoreService)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local Leaderboard = require(script.Parent.Leaderboard)

return function()
	it("should update new key and clear old key on player disconnecting", function()
		local datastore = MockDataStoreService:GetOrderedDataStore(tostring({}))
		local leaderboard = Leaderboard.new(Rodux.Store.new(RoduxFeatures.reducer), datastore, warn)

		local userId = 1
		local one = { KOs = 1, WOs = 0 }
		local two = { KOs = 2, WOs = 1 }

		leaderboard:OnUserDisconnecting(userId, one, nil):await()
		expect(datastore:GetAsync(Leaderboard.serializeKey(userId, one.WOs))).to.equal(one.KOs)

		leaderboard:OnUserDisconnecting(userId, two, one):await()
		expect(datastore:GetAsync(Leaderboard.serializeKey(userId, two.WOs))).to.equal(two.KOs)
		expect(datastore:GetAsync(Leaderboard.serializeKey(userId, one.WOs))).to.equal(nil)
	end)

	it("should return top 100 player results, clearing and not displaying any dup entries", function()
		local datastore = MockDataStoreService:GetOrderedDataStore(tostring({}))
		local store = Rodux.Store.new(RoduxFeatures.reducer)
		local leaderboard = Leaderboard.new(store, datastore, function() end)

		local userId = 1
		local one = { KOs = 1, WOs = 0 }
		local two = { KOs = 2, WOs = 1 }
		local oldKey = Leaderboard.serializeKey(userId, one.WOs)

		local removeAsync = datastore.RemoveAsync
		datastore.RemoveAsync = function(self, key)
			if key == oldKey then
				error("this will prevent the old key from being cleared")
			end

			return removeAsync(self, key)
		end

		leaderboard:OnUserDisconnecting(userId, one, nil):await()
		leaderboard:OnUserDisconnecting(userId, two, one):await()

		datastore.RemoveAsync = removeAsync
		leaderboard:Update()

		expect(#store:getState().leaderboard.users).to.equal(1)
		expect(store:getState().leaderboard.users[1].KOs).to.equal(two.KOs)
		expect(store:getState().leaderboard.users[1].WOs).to.equal(two.WOs)
		expect(datastore:GetAsync(oldKey)).to.equal(nil)
	end)
end
