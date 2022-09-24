local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local settingCategory = require(script.Parent.settingCategory)
local ThemeContext = require(script.Parent.Parent.ThemeContext)

local LocalPlayer = Players.LocalPlayer

local function contents(props, hooks)
    local self = hooks.useValue()
    if not next(self) then
        self.listRef = Roact.createRef()
        self.contentsY, self.setContentsY = Roact.createBinding(0)
        self.scrollingEnabled, self.setScrollingEnabled = Roact.createBinding(true)
    end

    hooks.useEffect(function()
        self.setContentsY(self.listRef:getValue().AbsoluteContentSize.Y)
    end, self)

    -- lol
    hooks.useEffect(function()
        local con = props.selectEvent:Connect(function(getCategory)
            local index = table.find(props.categories, getCategory())

            local children = self.listRef:getValue().Parent:GetChildren()
            local y = 0
            for i=1, index-1 do
                local child = children[i]
                y += child.AbsoluteSize.Y
            end

            self.listRef:getValue().Parent.Parent.CanvasPosition = Vector2.new(0, y)
        end)

        return function()
            con:Disconnect()
        end
    end, {
        event = props.selectEvent;
    })

    local theme = hooks.useContext(ThemeContext)

    local categoryByName = {}
    local children = {}
    for i, category in ipairs(props.categories) do
        local name = string.char(i)
        categoryByName[name] = category
        children[name] = e(settingCategory, {
            settings = props.settings[category.name];
            category = category;
            changedSettings = props.changedSettings;
            onSettingChanged = props.onSettingChanged;
            onSettingCanceled = props.onSettingCanceled;
            onPrompt = props.onPrompt;
        })    
    end

    children.UIListLayout = e("UIListLayout", {
        [Roact.Ref] = self.listRef;
        Padding = UDim.new(0, 10);
        HorizontalAlignment = Enum.HorizontalAlignment.Center;
    })

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

        [Roact.Change.CanvasPosition] = function()
            local currentY = self.listRef:getValue().Parent.Parent.CanvasPosition.Y

            local y = -1
            for _, child in pairs(self.listRef:getValue().Parent:GetChildren()) do
                if not child:IsA("GuiObject") then
                    continue
                end

                y += child.AbsoluteSize.Y

                if
                    y >= currentY
                    and categoryByName[child.Name]
                    and child.Name ~= props.categoryBinding:getValue().name
                then
                    props.onCategoryChanged(categoryByName[child.Name])
                    break
                end
            end
        end;
    }, e("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 20, 0, 0);
        Size = UDim2.new(1, -20 - 20 - 12, 1, 0);
    }, children))
end

return RoactHooks.new(Roact)(contents)