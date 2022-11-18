local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local AutoUIScale = require(script.Parent.Parent.AutoUIScale)
local draggable = require(script.Parent.Parent.draggable)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local function window(props, hooks)
	local theme = hooks.useContext(ThemeContext)
	local topRef = hooks.useBinding()
    local positionBinding, setPositionBinding = hooks.useBinding(UDim2.new(0.5, 0, 0.5, 0))

	return e("ImageLabel", {
        BackgroundTransparency = 1;
        
        ImageColor3 = theme.background;
        Image = "rbxassetid://9264310289";
        ScaleType = Enum.ScaleType.Slice;
        SliceCenter = Rect.new(Vector2.new(128, 128), Vector2.new(128, 128));
        SliceScale = 0.1;
        
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = positionBinding,
        Size = props.size;
    }, {
        UIScale = e(AutoUIScale, {
            minScaleRatio = 0.5;
            maxScaleRatio = 2;
        });
        Top = e(draggable, {
            topRef = topRef;
            positionBinding = {binding = positionBinding, set = setPositionBinding};
            outerRef = props.outerRef;

            enabled = props.draggable;

            anchorPoint = Vector2.new(0, 1);
            size = UDim2.new(1, 0, 0, 60)
        }, {
            Title = e("ImageLabel", {
                [Roact.Ref] = topRef;

                ImageColor3 = theme.foreground;
                Image = "rbxassetid://9264443152";
                ScaleType = Enum.ScaleType.Slice;
                SliceCenter = Rect.new(Vector2.new(128, 128), Vector2.new(128, 128));
                SliceScale = 0.1;
                
                BorderSizePixel = 0;
                Position = UDim2.new(0, 0, 0, 0);
                Size = UDim2.fromScale(1, 1);
                BackgroundTransparency = 1;
            }, {
                Icon = e("ImageLabel", {
                    Image = props.image;
                    BackgroundTransparency = 1;

                    Size = props.imageSize and UDim2.fromOffset(props.imageSize.X, props.imageSize.Y) or UDim2.fromOffset(0, 0);
                    AnchorPoint = Vector2.new(0, 0.5);
                    Position = UDim2.new(0, 10, 0.5, 0);
                });

                TextLabel = e("TextLabel", {
                    Text = props.name;
                    Font = Enum.Font.GothamBold;
                    TextColor3 = theme.title;
                    TextSize = 38;
                    TextXAlignment = props.image and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center;

                    BackgroundTransparency = 1;
                    Size = UDim2.fromScale(1, 1);
                    AnchorPoint = props.image and Vector2.new(0, 0) or Vector2.new(0.5, 0);
                    Position = props.image and UDim2.new(0, props.imageSize.X + 10 + 10, 0, 0) or UDim2.new(0.5, 0, 0, 0);
                });

                Close = e("ImageButton", {
                    BackgroundTransparency = 1;

                    AnchorPoint = Vector2.new(1, 0.5);
                    Position = UDim2.new(1, -5, 0.5, 0);
                    Size = UDim2.new(0, 50, 0, 50);
                    Image = "http://www.roblox.com/asset/?id=5107150301";

                    [Roact.Event.MouseButton1Down] = function()
                        props.onClosed()
                    end;

                    Visible = props.useExitButton;
                });
            })
        });

        Children = Roact.createFragment(props[Roact.Children]);
    })
end

return RoactHooks.new(Roact)(window)