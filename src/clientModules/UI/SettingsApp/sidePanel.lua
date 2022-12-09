local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local ThemeContext = require(script.Parent.Parent.ThemeContext)

local e = Roact.createElement

local function sidePanel(props, hooks)
	local theme = hooks.useContext(ThemeContext)

	local children = {}
	for i, settingCategory in ipairs(props.settingCategories) do
		children[string.char(i)] = e("ImageButton", {
			Size = props.iconSize,
			Image = settingCategory.imageId,
			BackgroundTransparency = 1,

			[Roact.Event.MouseButton1Down] = function()
				props.onPressed(settingCategory)
			end,
		}, {
			Outline = e("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(1, 10, 1, 10),
				Position = UDim2.new(0.5, 0, 0.5, 0),

				Visible = props.activeCategory:map(function(activeCategory)
					return activeCategory.name == settingCategory.name
				end),
			}, {
				UIStroke = e("UIStroke", {
					Color = theme.highContrast,
					Thickness = 2,
				}),
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		})
	end

	children.UIlistLayout = e("UIListLayout", {
		Padding = UDim.new(0, 30),

		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.Name,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})

	return e("Frame", {
		AnchorPoint = Vector2.new(0, 0),
		Size = props.size,
		BackgroundTransparency = 1,
	}, {
		e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			SideBar = e("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Size = UDim2.new(0, 4, 1, 0),
				Position = UDim2.new(1, 4, 0, 0),

				BackgroundColor3 = props.dividerColor,
				BorderSizePixel = 0,
				BackgroundTransparency = 0,
			}),
			List = e("Frame", {
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
			}, children),
		}),
	})
end

return RoactHooks.new(Roact)(sidePanel)
