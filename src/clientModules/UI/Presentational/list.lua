local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local e = Roact.createElement

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local function list(props, hooks)
    local theme = hooks.useContext(ThemeContext)

    local self = hooks.useValue()
    if not next(self) then
        self.listRef = Roact.createRef()
        self.contentsY, self.setContentsY = Roact.createBinding(0)
        self.scrollingEnabled, self.setScrollingEnabled = Roact.createBinding(true)
    end

    hooks.useEffect(function()
        self.setContentsY(self.listRef:getValue().AbsoluteContentSize.Y)
    end, self)

    -- Prevent scrolling eating input when zoomed in. This is actually impossible to otherwise escape.
    hooks.useEffect(function()
        local connection = RunService.Heartbeat:Connect(function()
            if not LocalPlayer then
                return
            end

            local character = LocalPlayer.Character
            if not character then
                return
            end

            local pPart = character.PrimaryPart
            if not pPart then
                return
            end

            if (Workspace.CurrentCamera.CFrame.Position - pPart.Position).Magnitude > 1 then
                self.setScrollingEnabled(true)
            else
                self.setScrollingEnabled(false)
            end
        end)

        return function()
            connection:Disconnect()
        end
    end)

	return e("ScrollingFrame", {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 1, 0);

        ScrollingEnabled = self.scrollingEnabled:map(function(enabled)
            return enabled
        end);
        ScrollBarThickness = 12;
        ScrollBarImageColor3 = theme.scrollbar;
        ScrollingDirection = Enum.ScrollingDirection.Y;
        CanvasSize = self.contentsY:map(function(contentsY)
            return UDim2.new(1, 0, 0, contentsY)
        end);
    }, {
        UIListLayout = e("UIListLayout", {
            [Roact.Ref] = self.listRef;
            Padding = UDim.new(0, props.padding);
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
        });
        ListItems = Roact.createFragment(props[Roact.Children]);
    })
end

return RoactHooks.new(Roact)(list)