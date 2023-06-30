local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions
local getSavedSetting = RoduxFeatures.selectors.getSavedSetting
local getLocalSetting = RoduxFeatures.selectors.getLocalSetting

local UserId = Players.LocalPlayer.UserId

return {
	Bomb = {
		bombJump = {

			-- Performs the action associated with the input. Returns whether it was successful or not.
			-- nil = did nothing.
			perform = function(tool, state)
				if state == Enum.UserInputState.Begin then
					return tool.module:FireAndBombJump()
				end
			end,
			-- Optional. Runs every frame. Whether to enable the keybind input. It will continue to be shown no matter what this returns.
			isActive = function(new)
				if getSavedSetting(new, UserId, "bombJumpDefault") then
					return false
				end

				return getSavedSetting(new, UserId, "bombJumpKeybind") ~= nil
			end,
			-- Optional. Handles honoring the enabled/disabled keybind.
			setEnabled = function(enabled)
				_G.BB.Settings.BombJump = not enabled
			end,
			-- Translates tool state/game state state into text every frame.
			text = function(tool, root)
				return if tool.module.canBombJump then "Bomb jump" else "Bomb jump - reloading",
					if getSavedSetting(root.Store:getState(), UserId, "bombJumpDefault")
						then "Stop click and jump"
						else nil
			end,
		},
	},

	Trowel = {
		trowelVisualization = {
			perform = function(_tool, state, root)
				if state == Enum.UserInputState.Begin then
					root.Store:dispatch(actions.saveSettings(UserId, {
						trowelVisualization = not getLocalSetting(root.Store:getState(), "trowelVisualization"),
					}))

					return true
				end
			end,
			-- Optional. Runs every frame. Whether to enable the keybind input. It will continue to be shown no matter what this returns.
			isActive = function()
				return true
			end,
			-- Optional. Handles honoring the enabled/disabled keybind.
			setEnabled = function() end,
			text = function(_, root)
				if getLocalSetting(root.Store:getState(), "trowelVisualization") then
					return "Trowel visualization - on"
				else
					return "Trowel visualization - off"
				end
			end,
		},
	},
}
