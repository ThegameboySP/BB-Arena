local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

local LockCommands = require(script.Parent.LockCommands)

return function()
	local store
	local lockCommands
	beforeEach(function()
		store = Rodux.Store.new(RoduxFeatures.reducer, nil, { Rodux.thunkMiddleware })
		lockCommands = LockCommands.new(store)
	end)

	it("should lock a command from lower ranking users", function()
		store:dispatch(actions.setAdmin(1, 2, nil))
		store:dispatch(actions.setAdmin(2, 1, nil))

		lockCommands:lockCommand(1, { Name = "test" })

		expect(lockCommands:beforeRun(2, { Name = "test" })).to.never.equal(nil)
	end)

	it("should unlock a command locked by same ranking user", function()
		store:dispatch(actions.setAdmin(1, 2, nil))
		store:dispatch(actions.setAdmin(2, 2, nil))
		store:dispatch(actions.setAdmin(3, 1, nil))

		lockCommands:lockCommand(1, { Name = "test" })
		lockCommands:unlockCommand(2, { Name = "test" })

		expect(lockCommands:beforeRun(2, { Name = "test" })).to.equal(nil)
	end)

	it("should allow equal or higher ranking users to run the command", function()
		store:dispatch(actions.setAdmin(1, 2, nil))
		store:dispatch(actions.setAdmin(2, 2, nil))

		lockCommands:lockCommand(1, { Name = "test" })

		expect(lockCommands:beforeRun(2, { Name = "test" })).to.equal(nil)
	end)
end
