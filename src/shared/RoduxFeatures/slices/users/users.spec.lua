local Rodux = require(game:GetService("ReplicatedStorage").Packages.Rodux)
local Dictionary = require(game:GetService("ReplicatedStorage").Packages.Llama).Dictionary

local RoduxFeatures = require(script.Parent.Parent.Parent)
local reducer = RoduxFeatures.reducer
local actions = RoduxFeatures.actions
local selectors = RoduxFeatures.selectors

return function()
	describe("serialization", function()
		local function serializeCase()
			local store = Rodux.Store.new(reducer, nil, { Rodux.thunkMiddleware })

			store:dispatch(actions.setAdmin(1, 2))
			store:dispatch(actions.userJoined(2))
			store:dispatch(actions.setUserBanned(2, true, 1))
			store:dispatch(actions.setUserWhitelisted(2, true, 1))
			store:dispatch(actions.setAdmin(2, 1, 1))
			store:dispatch(actions.setReferee(2, true, 1))

			return reducer(store:getState(), actions.serialize(2))
		end

		it("should serialize properly", function()
			local serialized = serializeCase().users

			expect(serialized.banned["2"]).to.equal(1)
			expect(serialized.whitelisted["2"]).to.equal(1)
			expect(serialized.admins["2"]).to.equal(1)
			expect(serialized.referees["2"]).to.equal(true)
			expect(serialized.activeUsers["2"]).to.be.ok()
		end)

		it("should deserialize properly", function()
			local deserialized = reducer(nil, RoduxFeatures.actions.deserialize(serializeCase())).users

			expect(deserialized.banned[2]).to.equal(1)
			expect(deserialized.whitelisted[2]).to.equal(1)
			expect(deserialized.admins[2]).to.equal(1)
			expect(deserialized.referees[2]).to.equal(true)
			expect(deserialized.activeUsers[2]).to.be.ok()
		end)
	end)

	describe("admining", function()
		local store
		beforeEach(function()
			store = Rodux.Store.new(reducer, nil, { Rodux.thunkMiddleware })
		end)

		it("should never allow a user to admin greater than his rank", function()
			store:dispatch(actions.setAdmin(0, 1, nil))
			store:dispatch(actions.setAdmin(1, 0, nil))
			store:dispatch(actions.setAdmin(1, 2, 0))
			expect(store:getState().users.admins[1]).to.equal(0)
		end)

		it("should never allow a user to demote a user with greater rank", function()
			store:dispatch(actions.setAdmin(0, 1, nil))
			store:dispatch(actions.setAdmin(1, 2, nil))
			store:dispatch(actions.setAdmin(1, 0, 0))
			expect(store:getState().users.admins[1]).to.equal(2)
		end)
	end)

	describe("bans and whitelisting", function()
		local store
		beforeEach(function()
			store = Rodux.Store.new(reducer, nil, { Rodux.thunkMiddleware })
			store:dispatch(actions.setAdmin(1, 1, nil))
			store:dispatch(actions.setAdmin(2, 2, nil))
		end)

		it("should never allow an admin to ban another of equal or greater rank", function()
			store:dispatch(actions.setAdmin(3, 1, nil))
			store:dispatch(actions.setUserBanned(1, true, 3))
			expect(store:getState().users.banned[1]).to.equal(nil)

			store:dispatch(actions.setUserBanned(2, true, 3))
			expect(store:getState().users.banned[2]).to.equal(nil)
		end)

		it("should whitelist every online user on server lock", function()
			store:dispatch(actions.userJoined(0))
			store:dispatch(actions.userJoined(1))
			store:dispatch(actions.userJoined(2))

			store:dispatch(actions.setServerLocked(true, 1))
			expect(#Dictionary.keys(store:getState().users.whitelisted)).to.equal(3)
		end)

		it("whitelisting should act as an override for server locking", function()
			store:dispatch(actions.userJoined(3))
			store:dispatch(actions.setServerLocked(true, 2))
			expect(selectors.canUserBeLockKicked(store:getState(), 3)).to.equal(false)
		end)

		it("banning should only work as long as the banning user's admin stays higher", function()
			store:dispatch(actions.setUserBanned(1, true, 2))
			expect(selectors.canUserBeKickedBy(store:getState(), 1, 2)).to.equal(true)
			store:dispatch(actions.setAdmin(2, 0, nil))
			expect(selectors.canUserBeKickedBy(store:getState(), 1, 2)).to.equal(false)
		end)
	end)
end
