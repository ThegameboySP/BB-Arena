local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local inventoryHotkeys = require(ReplicatedStorage.ClientModules.UI.Presentational.inventoryHotkeys)
local AutoUIScale = require(script.Parent.Parent.AutoUIScale)

local PADDING = 4
local ITEM_SIZE = 62

local function healthbar(props, hooks)
    local frameRef = hooks.useBinding()
    local lastHealthTable = hooks.useValue(props.maxHealth)

    hooks.useEffect(function()
        if lastHealthTable.value > props.health then
            local makeup = Instance.new("Frame")
            makeup.Name = "Makeup"
            makeup.Size = UDim2.new(lastHealthTable.value / props.maxHealth, 0, 1, 0)

            makeup.BackgroundTransparency = 0
            makeup.BackgroundColor3 = Color3.fromRGB(150, 181, 37)
            makeup.BorderSizePixel = 0
            makeup.ZIndex = -1
            makeup.Parent = frameRef:getValue()

            local tween = TweenService:Create(makeup, TweenInfo.new(0.5), {
                BackgroundTransparency = 1;
            })

            tween:Play()
            tween.Completed:Once(function()
                makeup.Parent = nil
            end)

            lastHealthTable.value = props.health
        end
    end)

    return e("Frame", {
        [Roact.Ref] = frameRef;

        AnchorPoint = props.anchorPoint;
        Position = props.position;

        BorderSizePixel = 0;
        BackgroundColor3 = Color3.fromRGB(180, 29, 29);
    }, {
        Green = e("Frame", {
            Size = UDim2.new(props.health / props.maxHealth, 0, 1, 0);
            BackgroundColor3 = Color3.fromRGB(75, 181, 37);
            BorderSizePixel = 0;
        });

        UIStroke = e("UIStroke", {
            Color = Color3.fromRGB(16, 17, 19);
            Transparency = 0.55;
            Thickness = 4;
            LineJoinMode = Enum.LineJoinMode.Miter;
        });

        HealthDisplay = e("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.new(0.5, 0, 0.5, 0);

            BackgroundTransparency = 1;

            FontFace = Font.fromName("RobotoMono", Enum.FontWeight.Bold);
            TextSize = 18;
            Text = string.format("%d/%d", props.health, props.maxHealth);
            TextXAlignment = Enum.TextXAlignment.Center;
            TextYAlignment = Enum.TextYAlignment.Center;
            TextColor3 = Color3.fromRGB(255, 255, 255);

            ZIndex = 2;
        })
    })
end

healthbar = RoactHooks.new(Roact)(healthbar)

local function hudMainWidget(props, hooks)
    local rootRef = hooks.useBinding()
    local tooltipRef = hooks.useBinding()
    local scaleBinding, setScaleBinding = hooks.useBinding(1)

    hooks.useEffect(function()
        local root = rootRef:getValue()

        local healthbarGui = root.Contents:FindFirstChild("Healthbar")
        if healthbarGui then
            local itemsLen = #props.items
            local contentSizeX = ITEM_SIZE * itemsLen + ((itemsLen - 1) * PADDING)
            healthbarGui.Size = UDim2.fromOffset(contentSizeX - 8, 18)
        end
    end)

    hooks.useEffect(function()
        local activeTween
        local connection = props.failedAction:Connect(function()
            if activeTween and activeTween.PlaybackState == Enum.PlaybackState.Playing then
                return
            end

            local tooltip = tooltipRef:getValue()
            activeTween = TweenService:Create(tooltip, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1, true), {
                TextColor3 = Color3.fromRGB(255, 127, 0);
            })

            activeTween:Play()
        end)

        return function()
            if activeTween then
                activeTween:Cancel()
                tooltipRef:getValue().TextColor3 = Color3.new(1, 1, 1)
            end

            connection:Disconnect()
        end
    end, {})

    local hasHealthbar = props.health ~= props.maxHealth

	return e("Frame", {
        [Roact.Ref] = rootRef;

        Size = UDim2.new(1, 0, 1, 0);
        Position = UDim2.new(0, 0, 0, -PADDING);
        BackgroundTransparency = 1;
    }, {
        Contents = e("Frame", {
            AnchorPoint = Vector2.new(0.5, 1);
            Size = UDim2.new(1, 0, 1, 0);
            Position = UDim2.new(0.5, 0, 1, 0);

            BackgroundTransparency = 1;
        }, {
            UIScale = e(AutoUIScale, {
                minScaleRatio = 0.8;
                maxAxisSize = 500;
                onScaleChanged = setScaleBinding;
            });
    
            Tooltip = e("TextLabel", {
                [Roact.Ref] = tooltipRef;
    
                AnchorPoint = Vector2.new(0.5, 1);
                Position = UDim2.new(0.5, 0, 1, -(ITEM_SIZE + (hasHealthbar and (PADDING + 4*2 + 18) or 0) + PADDING));
                Size = UDim2.new(0, 300, 0, 20);
    
                BackgroundTransparency = 1;
                FontFace = Font.fromName("Gotham", Enum.FontWeight.Bold);
                TextColor3 = Color3.new(1, 1, 1);
                TextSize = 20;
                TextStrokeTransparency = 0.4;
    
                RichText = false;
                Text = props.toolTip or "";
            });
    
            Healthbar = if not hasHealthbar then nil else e(healthbar, {
                anchorPoint = Vector2.new(0.5, 1);
                position = UDim2.new(0.5, 0, 1, -(ITEM_SIZE + PADDING + 4));
    
                health = props.health;
                maxHealth = props.maxHealth;
            });
    
            Items = e("Frame", {
                Size = UDim2.new(1, 0, 1, 0);
                BackgroundTransparency = 1;
                ZIndex = 2;
            }, {
                Items = e(inventoryHotkeys, {
                    padding = PADDING;
                    items = props.items;
                    equippedItemName = props.equippedItemName;
                    rootRef = rootRef;
                    scaleBinding = scaleBinding;
                    onEquipped = props.onEquipped;
                })
            })
        })
    })
end

return RoactHooks.new(Roact)(hudMainWidget)