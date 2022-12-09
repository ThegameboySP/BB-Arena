local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local e = Roact.createElement

local ThemeContext = require(script.Parent.ThemeContext)
local Themes = require(script.Parent.Themes)
local ThemeController = Roact.Component:extend("ThemeController")

function ThemeController:init(props)
	self.props = props
	self:setState({
		theme = Themes.default,
	})
end

function ThemeController:render()
	return e(ThemeContext.Provider, {
		value = self.state.theme,
		setTheme = function(theme)
			self:setState({
				value = theme,
			})
		end,
	}, self.props[Roact.Children])
end

return ThemeController
