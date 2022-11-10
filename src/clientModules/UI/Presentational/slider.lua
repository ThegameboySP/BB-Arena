local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local e = Roact.createElement

local listeningInput = {
    [Enum.UserInputType.MouseButton1] = true;
    [Enum.UserInputType.Touch] = true;
}

local function slider(props, hooks)
    local barRef = hooks.useState(Roact.createRef())
    local self = hooks.useValue()
    local theme = hooks.useContext(ThemeContext)

    hooks.useEffect(function()
        local connections = {}

        local function onMoved(position)
            if not self.held then
                return
            end

            local rbxBar = barRef:getValue()
            local min = rbxBar.AbsolutePosition.X
            local max = min + rbxBar.AbsoluteSize.X

            local percent = (math.clamp(position.X, min, max) - min) / (max - min)
            props.onChanged(percent)
        end

        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                onMoved(input.Position)
            end
        end))

        table.insert(connections, UserInputService.TouchMoved:Connect(function(input)
            onMoved(input.Position)
        end))

        table.insert(connections, UserInputService.InputEnded:Connect(function(input)
            if listeningInput[input.UserInputType] then
                self.held = false
            end
        end))

        return function()
            for _, connection in connections do
                connection:Disconnect()
            end
        end
    end, self)

    return e("ImageLabel", {
        [Roact.Ref] = barRef;
        
        AnchorPoint = props.anchor;
        Position = props.position;
        Size = UDim2.new(0, 150, 0, 10);

        Image = "rbxassetid://9263896916";
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
		SliceScale = 1;

        BackgroundTransparency = 1;
        ImageColor3 = if props.inactive then theme.accent:Lerp(theme.inactive, 0.6) else theme.accent;
    }, {
        Roact.createFragment(props[Roact.Children]),

        Marker = e(props.inactive and "ImageLabel" or "ImageButton", {
            [Roact.Event.MouseButton1Down] = if props.inactive then nil else function()
                self.held = true
            end;

            Size = UDim2.fromOffset(20, 20);
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.fromOffset(props.value * 150, 5);

            Image = "rbxassetid://9263896916";
            ScaleType = Enum.ScaleType.Slice;
            SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
            SliceScale = 1;

            BackgroundTransparency = 1;
            ImageColor3 = if props.inactive then theme.highContrast:Lerp(theme.inactive, 0.6) else theme.highContrast;

            ZIndex = 2;
        });

        Inactive = e("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0);
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, (1 - props.value) * 150, 1, 0);

            Image = "rbxassetid://9263896916";
            ScaleType = Enum.ScaleType.Slice;
            SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
            SliceScale = 1;

            BackgroundTransparency = 1;
            ImageColor3 = theme.inactive;
            ZIndex = 1;
        });
    })
end

return RoactHooks.new(Roact)(slider)