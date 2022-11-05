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

    return roundv2(pos - originalPos)
end

local function v2(v3)
    return Vector2.new(v3.X, v3.Y)
end

local function getScale(binding)
    return if binding then binding:getValue() else 1
end

-- topRef is the active GuiObject that takes input.
-- positionBinding = {set(), binding}
-- scaleBinding? = binding
-- outerRef is the containing GuiObject which represents the allowable space to drag.
local function draggable(props, hooks)
    local state = hooks.useValue()

    hooks.useEffect(function()
        local connections = {}

        if props.enabled then
            state.lastMousePosition = state.lastMousePosition or Vector3.zero
            state.lastTopPosition = state.lastTopPosition or nil
            state.lastRootPosition = state.lastRootPosition or nil

            state.hasDragged = if state.hasDragged then state.hasDragged else false

            local tolerance = props.tolerance or 0

            table.insert(connections, UserInputService.InputBegan:Connect(function(input)
                if listeningInput[input.UserInputType] and within(props.topRef:getValue(), input.Position) then
                    state.lastTopPosition = props.topRef:getValue().AbsolutePosition
                    state.lastRootPosition = props.positionBinding.binding:getValue()
                    state.lastMousePosition = input.Position
                    state.isPressed = true
                end
            end))

            table.insert(connections, UserInputService.InputEnded:Connect(function(input)
                if listeningInput[input.UserInputType] then
                    state.isPressed = false

                    if state.hasDragged and props.onDragReleased then
                        props.onDragReleased()
                    end

                    state.hasDragged = false
                end
            end))

            local function onMoved(delta)
                if state.isPressed then
                    local top = props.topRef:getValue()

                    local cappedDelta = capDelta(
                        props.outerRef:getValue().AbsoluteSize,
                        state.lastTopPosition,
                        top.AbsoluteSize,
                        top.AnchorPoint,
                        v2(delta)
                    ) / getScale(props.scaleBinding)

                    if state.hasDragged or cappedDelta.Magnitude >= tolerance then
                        props.positionBinding.set(state.lastRootPosition + UDim2.fromOffset(cappedDelta.X, cappedDelta.Y))

                        if not state.hasDragged then
                            state.hasDragged = true

                            if props.onDragBegin then
                                props.onDragBegin()
                            end
                        end

                        if props.onDragged then
                            props.onDragged(cappedDelta)
                        end
                    end
                end
            end

            table.insert(connections, UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    onMoved(input.Position - state.lastMousePosition)
                end
            end))

            table.insert(connections, UserInputService.TouchMoved:Connect(function(input)
                onMoved(input.Position - state.lastMousePosition)
            end))
        end
        
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
        Active = props.enabled;
    }, props[Roact.Children])
end

return RoactHooks.new(Roact)(draggable)