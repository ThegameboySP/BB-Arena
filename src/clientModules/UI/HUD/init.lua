local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local e = Roact.createElement

local ThemeController = require(script.Parent.ThemeController)
local hudMainWidget = require(script.hudMainWidget)

local HUD = Roact.Component:extend("HUD")

function HUD:render()
    return e(ThemeController, {}, {
        HUD = e(hudMainWidget, self.props);
    })
end

return HUD