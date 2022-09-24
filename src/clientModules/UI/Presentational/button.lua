local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local e = Roact.createElement

local function button(props)
    local textBounds = TextService:GetTextSize(props.text, props.textSize, Enum.Font.Gotham, props.minSize or Vector2.new(math.huge, math.huge))
	
	local padding = props.padding or 20
    textBounds += Vector2.new(padding, padding)

	if props.minSize then
		textBounds = Vector2.new(
			math.max(props.minSize.X, textBounds.X),
			math.max(props.minSize.Y, textBounds.Y)
		)
	end

	return e("ImageButton", {
		Size = UDim2.fromOffset(textBounds.X, textBounds.Y);
		Position = props.position;
		AnchorPoint = props.anchor;

		Image = "rbxassetid://9263896916";
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
		SliceScale = 0.5;

		BackgroundTransparency = 1;
		ImageColor3 = props.color;

		[Roact.Event.MouseButton1Click] = function()
			props.onPressed()
		end;
	}, {
        TextLabel = e("TextLabel", {
            Font = Enum.Font.Gotham;
            Size = UDim2.fromScale(1, 1);
            BackgroundTransparency = 1;

            TextColor3 = props.textColor;
            Text = props.text;
            TextSize = props.textSize;
        })
	})
end

return RoactHooks.new(Roact)(button)