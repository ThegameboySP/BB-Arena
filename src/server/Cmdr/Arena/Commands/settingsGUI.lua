local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Roact = require(ReplicatedStorage.Packages.Roact)

local SettingsApp = require(ReplicatedStorage.ClientModules.UI.SettingsApp)

local setEnabled
if RunService:IsClient() then
    local tree
    
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.Name = "Settings"
    gui.Parent = Players.LocalPlayer.PlayerGui

    local isOn = false
    setEnabled = function(on)
        if (not not tree) == on then
            return
        end

        isOn = on
        if on then
            local roactTree = Roact.createElement(SettingsApp, {
                onClosed = function()
                    setEnabled(false)
                end;
            })

            roactTree = Roact.createElement(RoactRodux.StoreProvider, {
                store = Root.Store;
            }, {
                Main = roactTree
            })

            tree = Roact.mount(roactTree, gui)
        else
            Roact.unmount(tree)
            tree = nil

            -- For legacy menu GUI
            if _G.SettingsClosed then
                _G.SettingsClosed()
            end
        end
    end

    local function toggleEnabled()
        setEnabled(not isOn)
    end

    -- For legacy menu GUI
    _G.ToggleSettings = toggleEnabled
end

return {
	Name = "settingsGUI";
	Aliases = {"settings"};
	Description = "Open the settings GUI.";
	Group = "Any";
	Args = {};
    Run = function()
        setEnabled(true)
    end;
}