local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local e = Roact.createElement

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local function switch(props, hooks)
	local theme = hooks.useContext(ThemeContext)
	
	return e(props.inactive and "ImageLabel" or "ImageButton", {
		Size = UDim2.fromOffset(80, 30);
		Position = props.position;
		AnchorPoint = props.anchor;

		Image = "rbxassetid://9263896916";
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
		SliceScale = 1;

		BackgroundTransparency = 1;
		ImageColor3 =
			if props.inactive and props.value
			then theme.accent:Lerp(theme.inactive, 0.6)
			elseif not props.inactive and props.value
			then theme.accent
			else theme.inactive;

		[Roact.Event.MouseButton1Click] = if props.inactive then nil else function()
			if not props.inactive then
				props.onChanged()
			end
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
			ImageColor3 = if props.inactive then theme.highContrast:Lerp(theme.inactive, 0.6) else theme.highContrast;
		})
	})
end

return RoactHooks.new(Roact)(switch)