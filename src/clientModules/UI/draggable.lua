local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local listeningInput = {
    [Enum.UserInputType.MouseButton1] = true;
    [Enum.UserInputType.Touch] = true;
}

local function within(instance, mouse)
    local pos = instance.AbsolutePosition
    local size = instance.AbsoluteSize

    return
        mouse.X >= pos.X and mouse.X <= (pos.X + size.X)
        and mouse.Y >= pos.Y and mouse.Y <= (pos.Y + size.Y)
end

local function roundv2(v2)
    return Vector2.new(math.round(v2.X), math.round(v2.Y))
end

-- Caps the new mouse delta so the GUI isn't offscreen.
local function capDelta(maxSize, pos, size, anchorPoint, delta)
    local originalPos = pos

    pos += delta

    -- Anchor point can be anything. We force it to the center here.
    local anchorDelta = Vector2.new(0.5, 0.5) - anchorPoint
    pos += size * anchorDelta

    if (pos - size/2).X < (-size.X * 0.5) then
        pos = Vector2.new(pos.X + (size.X/2 - pos.X) - size.X * 0.5, pos.Y)
    
    elseif (pos + size/2).X > (maxSize.X + size.X * 0.5) then
        pos = Vector2.new((pos.X - ((pos.X + size.X/2) - maxSize.X) + size.X * 0.5), pos.Y)
    end

    if (pos - size/2).Y < 0 then
        pos = Vector2.new(pos.X, pos.Y + (size.Y/2 - pos.Y))
    
    elseif (pos + size/2).Y > maxSize.Y then
        pos = Vector2.new(pos.X, pos.Y - ((pos.Y + size.Y/2) - maxSize.Y))
    end

    -- Change anchor point back to its original value.
    pos -= size * anchorDelta

    local change = roundv2(pos - originalPos)
    return UDim2.fromOffset(change.X, change.Y)
end

local function v2(v3)
    return Vector2.new(v3.X, v3.Y)
end

-- Draggable must not be under UIScale or any other constraint that means 1 UDim != 1 real pixel. It should be near the top.
-- topRef is the active GuiObject that takes input.
-- rootRef is the top level GuiObject that moves the rest with itself.
-- outerRef is the containing GuiObject which represents the allowable space to drag.
local function draggable(props, hooks)
    hooks.useEffect(function()
        local connections = {}

        local lastMousePosition = Vector3.zero
        local lastTopPosition
        local lastRootPosition
        local isPressed = false

        table.insert(connections, UserInputService.InputBegan:Connect(function(input)
            if listeningInput[input.UserInputType] and within(props.topRef:getValue(), input.Position) then
                lastTopPosition = props.topRef:getValue().AbsolutePosition
                lastRootPosition = props.rootRef:getValue().Position
                lastMousePosition = input.Position
                isPressed = true
            end
        end))

        table.insert(connections, UserInputService.InputEnded:Connect(function(input)
            if listeningInput[input.UserInputType] then
                isPressed = false
            end
        end))

        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if isPressed and input.UserInputType == Enum.UserInputType.MouseMovement then
                local root = props.rootRef:getValue()
                local top = props.topRef:getValue()
                local delta = input.Position - lastMousePosition

                root.Position = lastRootPosition + capDelta(
                    props.outerRef:getValue().AbsoluteSize,
                    lastTopPosition,
                    top.AbsoluteSize,
                    top.AnchorPoint,
                    v2(delta)
                )
            end
        end))
        
        return function()
            for _, connection in connections do
                connection:Disconnect()
            end
        end
    end)

    return Roact.createElement("Frame", {
        BackgroundTransparency = 1;
        Size = props.size;
        Position = props.position;
        AnchorPoint = props.anchorPoint;
        -- Use Active so that dragging the element sinks the input.
        Active = true;
    }, props[Roact.Children])
end

return RoactHooks.new(Roact)(draggable)