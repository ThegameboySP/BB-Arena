local RoduxFeatures = require(script.Parent.Parent)
local reducer = RoduxFeatures.reducer
local actions = RoduxFeatures.actions

return function()
    it("should initialize a gamemode's stats and reset the rest when it starts", function()
        local state = reducer(nil, actions.userJoined(1))
        state = reducer(state, actions.incrementStatRaw(1, "KOs", 1))
        state = reducer(state, actions.gamemodeStarted("CTF"))

        expect(state.stats.visualStats[1].CTF_captures).to.equal(0)
        expect(state.stats.visualStats[1].KOs).to.equal(0)
        expect(state.stats.visibleRegisteredStats.CTF_captures).to.equal(true)
    end)

    it("should clear a gamemode's stats when it ends", function()
        local state = reducer(nil, actions.userJoined(1))
        state = reducer(state, actions.gamemodeStarted("CTF"))
        state = reducer(state, actions.gamemodeEnded("CTF"))

        expect(state.stats.visualStats[1].CTF_captures).to.equal(nil)
        expect(state.stats.visibleRegisteredStats.CTF_captures).to.equal(nil)
    end)

    it("should increment a stat", function()
        local state = reducer(nil, actions.userJoined(1))
        state = reducer(state, actions.incrementStatRaw(1, "KOs", 2))
        state = reducer(state, actions.incrementStatRaw(1, "KOs", 1))

        expect(state.stats.visualStats[1].KOs).to.equal(3)
        expect(state.stats.serverStats[1].KOs).to.equal(3)
        expect(state.stats.alltimeStats[1].KOs).to.equal(3)
    end)

    it("should serialize and deserialize properly", function()
        local state = reducer(nil, actions.userJoined(1))
        state = reducer(state, actions.incrementStatRaw(1, "KOs", 1))
        state = reducer(state, actions.serialize())

        state = reducer(nil, actions.deserialize(state))

        expect(state.stats.visualStats[1].KOs).to.equal(1)
        expect(state.stats.serverStats[1].KOs).to.equal(1)
        expect(state.stats.alltimeStats[1].KOs).to.equal(1)
        expect(type(state.stats.ranks[1])).to.equal("number")
    end)
end