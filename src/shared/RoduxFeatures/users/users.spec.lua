local Rodux = require(game:GetService("ReplicatedStorage").Packages.Rodux)
local Dictionary = require(game:GetService("ReplicatedStorage").Packages.Llama).Dictionary
local reducer = require(script.Parent.Parent).reducer
local actions = require(script.Parent.usersActions)

return function()
    local store
    beforeEach(function()
        store = Rodux.Store.new(reducer, nil, { Rodux.thunkMiddleware })
        store:dispatch(actions.setAdmin(1, 1, nil))
        store:dispatch(actions.setAdmin(2, 2, nil))
    end)

    it("whitelists and bans should undo each other", function()
        store:dispatch(actions.setUserWhitelisted(1, 2, true))
        expect(store:getState().users.whitelisted[1]).to.be.ok()

        store:dispatch(actions.setUserBanned(1, 2, true))
        expect(store:getState().users.whitelisted[1]).to.equal(nil)

        store:dispatch(actions.setUserWhitelisted(1, 2, true))
        expect(store:getState().users.banned[1]).to.equal(nil)
    end)

    it("should never allow a whitelist by a lesser admin than the banning one", function()
        store:dispatch(actions.setAdmin(3, 1, nil))
        store:dispatch(actions.setUserBanned(1, 2, true))
        store:dispatch(actions.setUserWhitelisted(1, 3, true))
        expect(store:getState().users.whitelisted[1]).to.equal(nil)
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
end