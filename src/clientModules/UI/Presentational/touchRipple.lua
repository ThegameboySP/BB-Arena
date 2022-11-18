local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)

local blendAlpha = require(script.Parent.Parent.Utils.blendAlpha)

local e = Roact.createElement

local function calculateRadius(ref, position)
    local container = ref:getValue()

    if container then
        local corner = Vector2.new(
            math.floor((1 - position.X) + 0.5),
            math.floor((1 - position.Y) + 0.5)
        )

        local size = container.AbsoluteSize
        local ratio = size / math.min(size.X, size.Y)

        return ((corner * ratio) - (position * ratio)).Magnitude
    end

    return 0
end

local function touchRipple(props, hooks)
    local ref = hooks.useBinding()
    local positionBinding, setPosition = hooks.useBinding(Vector2.new(0, 0))
    local styles, api = RoactSpring.useSpring(hooks, function()
        return {
            scale = 0;
            opacity = 0;
        }
    end)

    local transparency = styles.opacity:map(function(value)
        return 1 - value
    end)

    transparency = Roact.joinBindings({
        transparency,
        props.transparency,
    }):map(blendAlpha)

    return e("Frame", {
        [Roact.Ref] = ref;

        ClipsDescendants = true;

        Size = UDim2.new(1, 0, 1, 0);
        BackgroundTransparency = 1;

        [Roact.Event.InputBegan] = function(object, input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local position = Vector2.new(input.Position.X, input.Position.Y)
                local relativePosition = (position - object.AbsolutePosition) / object.AbsoluteSize

                setPosition(relativePosition)

                api.start({
                    from = {
                        scale = 0;
                        opacity = 0;
                    };
                    to = {
                        scale = 1;
                        opacity = 1;
                    };
                    config = { tension = 350 }
                })

                input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                    local userInputState = input.UserInputState

                    if
                        userInputState == Enum.UserInputState.Cancel
                        or userInputState == Enum.UserInputState.End
                    then
                        api.start({
                            opacity = 0;
                        })
                    end
                end)
            end
        end;
    }, {
        Circle = e("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5);

            BackgroundTransparency = 1;

            Image = "rbxassetid://2609138523";
            ImageColor3 = props.color;
            ImageTransparency = transparency;

            Size = Roact.joinBindings({
                scale = styles.scale;
                position = positionBinding;
            }):map(function(values)
                local targetSize = calculateRadius(ref, values.position) * 2
                local currentSize = targetSize * values.scale

                local container = ref:getValue()

                if container then
                    local containerSize = container.AbsoluteSize
                    local containerAspect = containerSize.X / containerSize.Y

                    return UDim2.new(
                        currentSize / math.max(containerAspect, 1), 0,
                        currentSize * math.min(containerAspect, 1), 0
                    )
                end
            end);

            Position = positionBinding:map(function(value)
                return UDim2.new(value.X, 0, value.Y, 0)
            end);
        });
    })
end

return RoactHooks.new(Roact)(touchRipple)