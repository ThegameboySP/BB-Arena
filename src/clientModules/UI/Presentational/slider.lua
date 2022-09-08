local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local e = Roact.createElement

local function slider(props, hooks)
    local barRef = hooks.useState(Roact.createRef())
    local self = hooks.useValue()
    local theme = hooks.useContext(ThemeContext)

    hooks.useEffect(function()
        local con = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end

            if not self.held then
                return
            end

            local rbxBar = barRef:getValue()
            local min = rbxBar.AbsolutePosition.X
            local max = min + rbxBar.AbsoluteSize.X

            local percent = (math.clamp(input.Position.X, min, max) - min) / (max - min)
            props.onChanged(percent)
        end)

        return function()
            con:Disconnect()
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
        ImageColor3 = theme.accent;
    }, {
        Roact.createFragment(props[Roact.Children]),

        Marker = e("ImageButton", {
            [Roact.Event.MouseButton1Down] = function()
                self.held = true
            end;
            [Roact.Event.InputEnded] = function(_, input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return
                end

                self.held = false
            end;

            Size = UDim2.fromOffset(20, 20);
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.fromOffset(props.value * 150, 5);

            Image = "rbxassetid://9263896916";
            ScaleType = Enum.ScaleType.Slice;
            SliceCenter = Rect.new(Vector2.new(15, 15), Vector2.new(15, 15));
            SliceScale = 1;

            BackgroundTransparency = 1;
            ImageColor3 = theme.highContrast;

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