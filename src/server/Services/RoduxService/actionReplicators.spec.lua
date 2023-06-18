local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions
local actionReplicators = require(script.Parent.actionReplicators)

return function()
	describe("users_saveSettings", function()
		it("should replicate properly", function()
			local map = actionReplicators.users_saveSettings.replicate(
				{ 1, 2 },
				actions.saveSettings(1, {
					lighting = 0.5,
					weaponTheme = "test",
				})
			)

			expect(map[1].payload.settings.lighting).to.equal(0.5)
			expect(map[1].payload.settings.weaponTheme).to.equal("test")
			expect(map[2].payload.settings.lighting).to.equal(nil)
			expect(map[2].payload.settings.weaponTheme).to.equal("test")

			local map2 = actionReplicators.users_saveSettings.replicate(
				{ 1, 2 },
				actions.saveSettings(1, {
					lighting = 0.5,
				})
			)

			expect(map2[1].payload.settings.lighting).to.equal(0.5)
			expect(map2[2]).to.equal(nil)
		end)

		it("should handle requests properly", function()
			expect(actionReplicators.users_saveSettings.request(
				1,
				actions.saveSettings(1, {
					lighting = 0.5,
				})
			)).to.never.equal(nil)
		end)
	end)
end
