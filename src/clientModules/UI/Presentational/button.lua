local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local e = Roact.createElement

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local function button(props, hooks)
    local theme = hooks.useContext(ThemeContext)

    local color
    if type(props.color) == "string" then
        color = theme[props.color]
    else
        color = props.color
    end

    local textColor
    if type(props.textColor) == "string" then
        textColor = theme[props.textColor]
    else
        textColor = props.textColor
    end

    local textBounds = TextService:GetTextSize(props.text, 28, Enum.Font.Gotham, Vector2.new(682, 1000))
    textBounds += Vector2.new(20, 20)

	return e("ImageButton", {
		Size = UDim2.fromOffset(textBounds.X, textBounds.Y);
		Position = props.position;
		AnchorPoint = props.anchor;

		Image = "rbxassetid://9263896916";
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
		SliceScale = 0.5;

		BackgroundTransparency = 1;
		ImageColor3 = color;

		[Roact.Event.MouseButton1Click] = function()
			props.onPressed()
		end;
	}, {
        TextLabel = e("TextLabel", {
            Font = Enum.Font.Gotham;
            Size = UDim2.fromScale(1, 1);
            BackgroundTransparency = 1;

            TextColor3 = textColor;
            Text = props.text;
            TextSize = 28;
        })
	})
end

return RoactHooks.new(Roact)(button)