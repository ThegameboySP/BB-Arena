local Rodux = require(game:GetService("ReplicatedStorage").Packages.Rodux)
local Dictionary = require(game:GetService("ReplicatedStorage").Packages.Llama).Dictionary
local reducer = require(script.Parent.Parent).reducer
local actions = require(script.Parent.usersActions)
local selectors = require(script.Parent.usersSelectors)

return function()
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
            store:dispatch(actions.setUserBanned(1, 3, true))
            expect(store:getState().users.banned[1]).to.equal(nil)
    
            store:dispatch(actions.setUserBanned(2, 3, true))
            expect(store:getState().users.banned[2]).to.equal(nil)
        end)
    
        it("should whitelist every online user on server lock", function()
            store:dispatch(actions.userJoined(0))
            store:dispatch(actions.userJoined(1))
            store:dispatch(actions.userJoined(2))
    
            store:dispatch(actions.setServerLocked(0, true))
            expect(#Dictionary.keys(store:getState().users.whitelisted)).to.equal(3)
        end)

        it("whitelisting should act as an override for server locking", function()
            store:dispatch(actions.userJoined(3))
            store:dispatch(actions.setServerLocked(2, true))
            expect(selectors.canUserBeLockKicked(store:getState(), 3)).to.equal(false)
        end)

        it("banning should only work as long as the banning user's admin stays higher", function()
            store:dispatch(actions.setUserBanned(1, 2, true))
            expect(selectors.canUserBeKickedBy(store:getState(), 1, 2)).to.equal(true)
            store:dispatch(actions.setAdmin(2, 0, nil))
            expect(selectors.canUserBeKickedBy(store:getState(), 1, 2)).to.equal(false)
        end)
    end)
end