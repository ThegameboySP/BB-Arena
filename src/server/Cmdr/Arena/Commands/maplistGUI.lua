local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Roact = require(ReplicatedStorage.Packages.Roact)

local MapListApp = require(ReplicatedStorage.ClientModules.UI.MapListApp)

local setEnabled

if RunService:IsClient() then
    local tree
    
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.Name = "MapList"
    gui.Parent = Players.LocalPlayer.PlayerGui

    local isOn = false
    setEnabled = function(on)
        if (not not tree) == on then
            return
        end

        isOn = on
        if on then
            local roactTree = Roact.createElement(MapListApp, {
                onClosed = function()
                    setEnabled(false)
                end;
                changeToMap = function(mapName)
                    local cmdr = Root:GetService("CmdrController").Cmdr
                    return cmdr.Dispatcher:EvaluateAndRun("changemap " .. mapName)
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
            if _G.MapListClosed then
                _G.MapListClosed()
            end
        end
    end

    local function toggleEnabled()
        setEnabled(not isOn)
    end

    -- For legacy menu GUI
    _G.ToggleMapList = toggleEnabled
end

return {
	Name = "maplistGUI";
	Aliases = {"maplist"};
	Description = "Open the map list GUI.";
	Group = "Any";
	Args = {};
    Run = function()
        setEnabled(true)
    end;
}