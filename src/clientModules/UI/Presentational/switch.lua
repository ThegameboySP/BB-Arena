local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local e = Roact.createElement

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local function switch(props, hooks)
	local theme = hooks.useContext(ThemeContext)
	
	return e("ImageButton", {
		Size = UDim2.fromOffset(80, 30);
		Position = props.position;
		AnchorPoint = props.anchor;

		Image = "rbxassetid://9263896916";
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
		SliceScale = 1;

		BackgroundTransparency = 1;
		ImageColor3 = props.value and theme.accent or theme.inactive;

		[Roact.Event.MouseButton1Click] = function()
			props.onChanged()
		end;
	}, {
		Circle = e("ImageLabel", {
			AnchorPoint = Vector2.new(1, 0.5);
			Size = UDim2.fromOffset(30, 30);
			Position = UDim2.fromScale(1, 0.5) + (props.value and UDim2.fromOffset(2, 0) or UDim2.fromOffset(-52, 0));
	
			Image = "rbxassetid://9263896916";
			ScaleType = Enum.ScaleType.Slice;
			SliceScale = 1;
			SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
	
			BackgroundTransparency = 1;
			ImageColor3 = theme.highContrast;
		})
	})
end

return RoactHooks.new(Roact)(switch)