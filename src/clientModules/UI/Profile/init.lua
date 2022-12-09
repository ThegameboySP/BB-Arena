local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local e = Roact.createElement

local ThemeController = require(script.Parent.ThemeController)
local profileMainWidget = require(script.profileMainWidget)

local ProfileApp = Roact.Component:extend("ProfileApp")

function ProfileApp:render()
	return e(ThemeController, {}, {
		ProfileApp = e(profileMainWidget, self.props),
	})
end

return ProfileApp
