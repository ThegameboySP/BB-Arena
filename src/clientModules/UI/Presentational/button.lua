local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local e = Roact.createElement

local function calculateSize(text, textSize, padding, minSize)
	local textBounds = TextService:GetTextSize(text, textSize, Enum.Font.Gotham, minSize or Vector2.new(math.huge, math.huge))
    textBounds += Vector2.new(padding or 20, padding or 20)

	if minSize then
		textBounds = Vector2.new(
			math.max(minSize.X, textBounds.X),
			math.max(minSize.Y, textBounds.Y)
		)
	end

	return UDim2.fromOffset(textBounds.X, textBounds.Y)
end

local function button(props, hooks)
	local theme = hooks.useContext(ThemeContext)

	return e(props.inactive and "ImageLabel" or "ImageButton", {
		Size = if type(props.text) == "string" then calculateSize(props.text, props.textSize, props.padding, props.minSize) else props.text:map(function(text)
			return calculateSize(text, props.textSize, props.padding, props.minSize)
		end);
		Position = props.position;
		AnchorPoint = props.anchor;

		Image = "rbxassetid://9263896916";
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
		SliceScale = 0.5;

		BackgroundTransparency = 1;
		ImageColor3 = if props.inactive then props.color:Lerp(theme.inactive, 0.6) else props.color;

		[Roact.Event.Activated] = if props.inactive then nil else function()
			if not props.inactive then
				props.onPressed()
			end
		end;
	}, {
        TextLabel = e("TextLabel", {
            Font = Enum.Font.Gotham;
            Size = UDim2.fromScale(1, 1);
            BackgroundTransparency = 1;

            TextColor3 = if props.inactive then props.textColor:Lerp(theme.inactive, 0.6) else props.textColor;
            Text = props.text;
            TextSize = props.textSize;
        })
	})
end

return RoactHooks.new(Roact)(button)