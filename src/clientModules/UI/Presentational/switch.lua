local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)

local e = Roact.createElement

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local function switch(props, hooks)
	local theme = hooks.useContext(ThemeContext)
	local styles, api = RoactSpring.useSpring(hooks, function()
		return {
			alpha = 1,
			config = { tension = 250 },
		}
	end)

	hooks.useEffect(function()
		api.start({ alpha = if props.value then 0 else 1 })
	end)

	return e(props.inactive and "ImageLabel" or "ImageButton", {
		Size = UDim2.fromOffset(80, 30),
		Position = props.position,
		AnchorPoint = props.anchor,

		Image = "rbxassetid://9263896916",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15)),
		SliceScale = 1,

		BackgroundTransparency = 1,
		ImageColor3 = if props.inactive and props.value
			then theme.accent:Lerp(theme.inactive, 0.6)
			elseif not props.inactive then styles.alpha:map(function(alpha)
				return theme.accent:Lerp(theme.inactive, alpha)
			end)
			else theme.inactive,

		[Roact.Event.MouseButton1Click] = if props.inactive
			then nil
			else function()
				if not props.inactive then
					props.onChanged()
				end
			end,
	}, {
		Inactive = e("ImageLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Size = styles.alpha:map(function(alpha)
				return UDim2.new(math.clamp(alpha, 0.35, 0.8), 0, 1, 0)
			end),
			Position = UDim2.new(1, 0, 0, 0),

			Image = "rbxassetid://9263896916",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15)),
			SliceScale = 1,

			ImageColor3 = theme.inactive,
			BackgroundTransparency = 1,
		}),
		Circle = e("ImageLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.fromOffset(30, 30),
			Position = styles.alpha:map(function(alpha)
				return UDim2.fromScale(1, 0.5) + UDim2.fromOffset(-50 * alpha, 0)
			end),

			Image = "rbxassetid://9263896916",
			ScaleType = Enum.ScaleType.Slice,
			SliceScale = 1,
			SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15)),

			BackgroundTransparency = 1,
			ImageColor3 = if props.inactive then theme.highContrast:Lerp(theme.inactive, 0.6) else theme.highContrast,

			ZIndex = 2,
		}),
	})
end

return RoactHooks.new(Roact)(switch)
