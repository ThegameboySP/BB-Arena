local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local e = Roact.createElement

local function textBox(props, hooks)
	local theme = hooks.useContext(ThemeContext)
	local self = hooks.useValue()
	if not next(self) then
		self.textboxRef = Roact.createRef()
	end

	local textMaxScreenSpace = Vector2.new(props.maxScreenSpace.X, 10_000)
	local initialTextBounds = TextService:GetTextSize("text", props.textSize, Enum.Font.Gotham, textMaxScreenSpace)
	local padding = props.maxScreenSpace.Y - initialTextBounds.Y

	textMaxScreenSpace -= Vector2.new(12 + padding, 0)

	hooks.useEffect(function()
		local textbox = self.textboxRef:getValue()
		local scrollingFrame = textbox.Parent

		local function updateTextboxSize()
			local textBounds =
				TextService:GetTextSize(textbox.Text, props.textSize, Enum.Font.Gotham, textMaxScreenSpace)

			textBounds = Vector2.new(
				math.clamp(textBounds.X, textMaxScreenSpace.X, math.huge),
				math.clamp(textBounds.Y, 30, math.huge)
			)

			textbox.Size = UDim2.fromOffset(textBounds.X, textBounds.Y)

			if props.canScroll then
				scrollingFrame.CanvasSize = UDim2.fromOffset(props.maxScreenSpace.X, textBounds.Y)
			else
				scrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
			end
		end

		local connection = textbox:GetPropertyChangedSignal("Text"):Connect(updateTextboxSize)

		return function()
			connection:Disconnect()
		end
	end)

	return e("ImageLabel", {
		Size = UDim2.fromOffset(props.maxScreenSpace.X + padding, props.maxScreenSpace.Y + padding),
		Position = props.position,
		AnchorPoint = props.anchor,

		Image = "rbxassetid://9263896916",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15)),
		SliceScale = 0.5,

		BackgroundTransparency = 1,
		ImageColor3 = if props.inactive then props.color:Lerp(theme.inactive, 0.6) else props.color,
	}, {
		ScrollingFrame = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.fromOffset(textMaxScreenSpace.X, props.textSize),
			BorderSizePixel = 0,

			ScrollBarThickness = 12,
			ScrollBarImageColor3 = theme.scrollbar,
			ScrollingEnabled = props.canScroll and not props.inactive,

			ScrollingDirection = Enum.ScrollingDirection.Y,
		}, {
			TextBox = e(props.inactive and "TextLabel" or "TextBox", {
				[Roact.Ref] = self.textboxRef,

				Font = Enum.Font.Gotham,
				Size = UDim2.fromOffset(textMaxScreenSpace.X, props.textSize),
				BackgroundTransparency = 1,

				PlaceholderText = if props.inactive then nil else "Type here...",

				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.new(0, padding, 0, padding),

				TextColor3 = if props.inactive then props.textColor:Lerp(theme.inactive, 0.6) else props.textColor,
				Text = props.text,
				TextSize = props.textSize,

				TextWrapped = true,
				ClearTextOnFocus = if props.inactive then nil else false,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,

				[Roact.Event.FocusLost] = if props.inactive
					then nil
					else function()
						local textbox = self.textboxRef:getValue()
						props.onTyped(textbox.Text)
					end,
			}),
		}),
	})
end

return RoactHooks.new(Roact)(textBox)
