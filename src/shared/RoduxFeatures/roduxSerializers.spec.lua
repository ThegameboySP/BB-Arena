local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(script.Parent)
local serializers = RoduxFeatures.serializers
local actions = RoduxFeatures.actions

return function()
    describe("stats_initializeUser", function()
        it("should serialize and deserialize properly", function()
            local store = Rodux.Store.new(RoduxFeatures.reducer)

            local entry = serializers.stats_initializeUser
            local state = store:getState()
            local action = actions.initializeUserStats(1, {
                KOs = 2;
                WOs = 1;
            })

            local result = entry.deserialize(entry.serialize(action, state), state)

            expect(result.payload.stats.KOs).to.equal(2)
            expect(result.payload.stats.WOs).to.equal(1)
        end)
    end)

    describe("rodux player initialization", function()
        it("should serialize and deserialize properly", function()
            local store = Rodux.Store.new(RoduxFeatures.reducer)
            store:dispatch(actions.initializeUserStats(2, {
                someStat = 1;
            }))

            store:dispatch(actions.saveSettings(2, {
                someOption = true;
            }))

            local result = RoduxFeatures.reducer(
                nil,
                actions.deserialize(RoduxFeatures.reducer(store:getState(), actions.serialize(1))
            ))

            expect(result.stats.alltimeStats[2].someStat).to.equal(1)
            expect(result.users.userSettings[2].someOption).to.equal(nil)

            local result2 = RoduxFeatures.reducer(
                nil,
                actions.deserialize(RoduxFeatures.reducer(store:getState(), actions.serialize(2))
            ))
            
            expect(result2.stats.alltimeStats[2].someStat).to.equal(1)
            expect(result2.users.userSettings[2].someOption).to.equal(true)
        end)
    end)
end