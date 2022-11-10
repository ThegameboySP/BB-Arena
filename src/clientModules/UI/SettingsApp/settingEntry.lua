local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local Dictionary = Llama.Dictionary
local e = Roact.createElement

local HUDConstants = require(ReplicatedStorage.ClientModules.UI.HUDConstants)
local switch = require(script.Parent.Parent.Presentational.switch)
local percentSlider = require(script.Parent.Parent.Presentational.percentSlider)
local rangeSlider = require(script.Parent.Parent.Presentational.rangeSlider)
local list = require(script.Parent.Parent.Presentational.list)
local button = require(script.Parent.Parent.Presentational.button)
local window = require(script.Parent.Parent.Presentational.window)
local textBox = require(script.Parent.Parent.Presentational.textBox)
local inventoryHotkeys = require(script.Parent.Parent.Presentational.inventoryHotkeys)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local Container = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

local MARGIN = 6
local TITLE_TEXT_SIZE = 28
local DESCRIPTION_TEXT_SIZE = 24

local function modal(props)
    return e(window, {
        size = UDim2.fromOffset(400, 400);
        name = props.name;
        outerRef = props.outerRef;

        useExitButton = false;
        draggable = true;
    }, {
        List = e("Frame", {
            BackgroundTransparency = 0;
            BackgroundColor3 = props.theme.background;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
        }, {
            List = e(list, {
                padding = 15;
            }, props.list);

            Bottom = e("Frame", {
                BackgroundTransparency = 0;
                BackgroundColor3 = props.theme.foreground;
                BorderSizePixel = 0;
                AnchorPoint = Vector2.new(0.5, 0);
                Size = UDim2.new(1, 0, 0, 50);
                Position = UDim2.new(0.5, 0, 1, 0);
            }, {
                Confirm = e(button, {
                    anchor = Vector2.new(0.5, 1);
                    position = UDim2.new(0.5, 0, 1, 0);
                    text = "Confirm";
                    textSize = 24;
                    textColor = props.theme.highContrast;
                    color = props.theme.background;

                    onPressed = function()
                        props.onFinished(true)
                    end;
                })
            });
        })
    })
end

modal = RoactHooks.new(Roact)(modal)

local function toolOrderModal(props, hooks)
    local items, setItems = hooks.useState(props.items)

    return e("Frame", {
        Size = UDim2.new(1, 0, 1, 0);
        Position = UDim2.new(0, 0, 0, -60);

        BackgroundTransparency = 1;
    }, {
        e(button, {
            position = UDim2.new(0.5, 0, 1, -66 -HUDConstants.HUD_PADDING*2);
            anchor = Vector2.new(0.5, 1);

            text = "Done";
            textSize = 20;
            onPressed = function()
                props.onOrderChanged(items)
            end;
        }),
        e("Frame", {
            Size = UDim2.new(1, 0, 1, 0);
            Position = UDim2.new(0, 0, 1, -HUDConstants.HUD_PADDING*2);
            AnchorPoint = Vector2.new(0, 1);

            BackgroundTransparency = 1;
        }, {
            Items = e(inventoryHotkeys, Dictionary.merge(props, {
                items = items;
                onOrderChanged = function(newOrder)
                    setItems(newOrder)
                end;
            }))
        });
    })
end

toolOrderModal = RoactHooks.new(Roact)(toolOrderModal)

local function getDescriptionSize(type)
    if type == "image" then
        return Vector2.new(600, 1000)
    elseif type == "sound" then
        return Vector2.new(650, 100)
    else
        return Vector2.new(682, 1000)
    end
end

local function settingEntry(props, hooks)
    local setting = props.setting
    -- The font size shrinks slower than its surrounding text label. Adding an extra line is easy.
    local descriptionSize = getDescriptionSize(props.setting.type)
    local descriptionBounds = TextService:GetTextSize(setting.description .. "\n", DESCRIPTION_TEXT_SIZE, Enum.Font.Gotham, descriptionSize)
    descriptionBounds = Vector2.new(descriptionSize.X, descriptionBounds.Y)

    local theme = hooks.useContext(ThemeContext)
    local prompt, setPrompt = hooks.useState(nil)
    local keybindCallback, setKeybindCallback = hooks.useState(nil)
    local styles, api = RoactSpring.useSpring(hooks, function()
        return { selectionOutlineTransparency = 1 }
    end)

    local outerRef = hooks.useBinding()

    hooks.useEffect(function()
        if keybindCallback then
            if not setting.valid then
                keybindCallback.callback(nil)
                return
            end

            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
                    keybindCallback.callback(input.KeyCode)
                    connection:Disconnect()
                else
                    keybindCallback.callback(nil)
                end
            end)

            return function()
                connection:Disconnect()
            end
        end
    end)

    if prompt == "enum" then
        local listItems = {}

        for name in setting.payload do
            listItems[name] = e("TextButton", {
                BackgroundTransparency = if setting.value == name then 0 else 1;
                BorderSizePixel = 0;
                BackgroundColor3 = theme.accent;

                Text = name;
                TextSize = 24;
                Font = Enum.Font.GothamSemibold;

                Size = UDim2.new(1, 0, 0, 24);
                TextColor3 = theme.highContrast;
                TextXAlignment = Enum.TextXAlignment.Center;

                [Roact.Event.MouseButton1Down] = function()
                    props.onSettingChanged(setting.id, name)
                end;
            })
        end

        prompt = e(modal, {
            theme = theme;
            list = listItems;
            name = setting.name;
            outerRef = outerRef;
            onFinished = function()
                props.onPrompt(false)
                setPrompt(nil)
            end;
        })
    end

    if prompt then
        prompt = e(Roact.Portal, {
            target = Container
        }, {
            Modal = e("ScreenGui", {
                [Roact.Ref] = outerRef;
                ResetOnSpawn = false;
            }, {
                Prompt = prompt;
            })
        })
    end

    local control
    if setting.type == "switch" then
        control = e(switch, {
            inactive = not setting.valid;
            value = setting.value;
            anchor = Vector2.new(1, 0.5);
            position = UDim2.new(1, -10, 0.5, 0);
            onChanged = function()
                props.onSettingChanged(setting.id, not setting.value)
            end;
        })
    elseif setting.type == "slider" then
        control = e(percentSlider, {
            inactive = not setting.valid;
            value = setting.value;
            anchor = Vector2.new(1, 0.5);
            position = UDim2.new(1, -10, 0.5, 0);
            onChanged = function(percent)
                props.onSettingChanged(setting.id, percent)
            end;
        })
    elseif setting.type == "range" then
        control = e(rangeSlider, {
            inactive = not setting.valid;
            value = setting.value;
            min = setting.payload.min;
            max = setting.payload.max;
            sign = setting.payload.sign;

            anchor = Vector2.new(1, 0.5);
            position = UDim2.new(1, -10, 0.5, 0);
            onChanged = function(value)
                props.onSettingChanged(setting.id, value)
            end;
        })
    elseif setting.type == "enum" then
        control = e(button, {
            inactive = not setting.valid;
            position = UDim2.new(1, -10, 0.5, 0);
            anchor = Vector2.new(1, 0.5);
            text = string.format("Press for list...\n%q", tostring(setting.value));
            color = theme.background;
            textColor = theme.text;
            textSize = 20;

            onPressed = function()
                props.onPrompt(true)
                setPrompt("enum")
            end;
        })
    elseif setting.type == "keybind" then
        control = e(button, {
            inactive = not setting.valid;
            position = UDim2.new(1, -10, 0.5, 0);
            anchor = Vector2.new(1, 0.5);
            text =
                if keybindCallback and keybindCallback.name == setting.name
                then "Waiting for input..."
                else string.format("Press for keybind...\n%q", tostring(setting.value));
            color = theme.background;
            textColor = theme.text;
            textSize = 20;

            onPressed = function()
                setKeybindCallback({
                    name = setting.name;
                    callback = function(keycode)
                        setKeybindCallback(nil)

                        if keycode then
                            props.onSettingChanged(setting.id, keycode.Name)
                        end
                    end;
                })
            end;
        })
    elseif setting.type == "image" then
        control = Roact.createFragment({
            e(textBox, {
                inactive = not setting.valid;
                position = UDim2.new(1, -10, 0.5, 0);
                anchor = Vector2.new(1, 0.5);
                text = setting.value;
                color = theme.background;
                textColor = theme.text;
                textSize = 20;
    
                canScroll = false;
                maxScreenSpace = Vector2.new(140, 24);
    
                onTyped = function(text)
                    props.onSettingChanged(setting.id, text)
                end;
            }),
            e("ImageLabel", {
                Position = UDim2.new(1, -160, 0.5, 0);
                AnchorPoint = Vector2.new(1, 0.5);
                Size = UDim2.fromOffset(85, 85);

                BackgroundTransparency = 1;
                Image = "rbxassetid://" .. setting.value;
            })
        })
    elseif setting.type == "sound" then
        control = Roact.createFragment({
            e(textBox, {
                inactive = not setting.valid;
                position = UDim2.new(1, -10, 0.5, 0);
                anchor = Vector2.new(1, 0.5);
                text = setting.value and setting.value or "";
                color = theme.background;
                textColor = theme.text;
                textSize = 20;
    
                canScroll = false;
                maxScreenSpace = Vector2.new(140, 24);
    
                onTyped = function(text)
                    if tonumber(text) then
                        props.onSettingChanged(setting.id, text)
                    end
                end;
            }),
            e("ImageButton", {
                Position = UDim2.new(1, -160, 0.5, 0);
                AnchorPoint = Vector2.new(1, 0.5);
                Size = UDim2.fromOffset(30, 30);

                BackgroundTransparency = 1;
                Image = "http://www.roblox.com/asset/?id=7203392850";

                [Roact.Event.MouseButton1Down] = function()
                    local sound
                    if setting.value == nil and setting.payload and setting.payload.defaultSound then
                        sound = setting.payload.defaultSound
                    else
                        sound = Instance.new("Sound")
                        sound.SoundId = "rbxassetid://" .. setting.value
                    end

                    if sound then
                        SoundService:PlayLocalSound(sound)
                    end
                end;
            })
        })
    elseif setting.type == "toolOrder" then
        local items = {}
        for _, itemName in setting.value do
            table.insert(items, {
                name = itemName;
                thumbnail = HUDConstants[itemName:upper() .. "_THUMBNAIL"];
            })
        end

        control = Roact.createFragment({
            e("Frame", {
                Position = UDim2.new(1, -118, 0.5, 40);
                AnchorPoint = Vector2.new(1, 0.5);
                ZIndex = 2;
            }, {
                UIScale = e("UIScale", {
                    Scale = 0.5;
                });
                tools = e(inventoryHotkeys, {
                    items = items;
                    scaleBinding = Roact.createBinding(0.05);
                    rootRef = outerRef;
                })
            }),
            e(button, {
                inactive = not setting.valid;
                position = UDim2.new(1, -10, 0.5, -16);
                anchor = Vector2.new(1, 0.5);
                text = "Press for tool order...";
                color = theme.background;
                textColor = theme.text;
                textSize = 20;
    
                onPressed = function()
                    props.onPrompt(true)
    
                    setPrompt(e(toolOrderModal, {
                            items = items;
                            rootRef = outerRef;
                            scaleBinding = props.scaleBinding;
                            onOrderChanged = function(newItems)
                                local order = {}
                                for _, item in newItems do
                                    table.insert(order, item.name)
                                end
    
                                props.onSettingChanged(setting.id, order)
                                props.onPrompt(false)
                                setPrompt(nil)
                            end;
                        })
                    )
                end;
            })
        })
    end

    return e("TextButton", {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 0, descriptionBounds.Y + 1 + TITLE_TEXT_SIZE + MARGIN + MARGIN);
        Text = "";

        [Roact.Event.MouseButton1Click] = if not setting.valid then nil else function()
            local isSelected = not props.selectedSettings:getValue()[setting.id]
            props.onSelectedChanged(setting.id, isSelected)
        end;
    }, {
        UIStroke = e("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = theme.accent:Lerp(Color3.new(1, 1, 1), 0.5);
            Transparency = styles.selectionOutlineTransparency;
            -- TODO: this is bad. fix me.
            Thickness = props.selectedSettings:map(function(selectedSettings)
                local isSelected = not selectedSettings[setting.id]
                local alpha = if isSelected then 1 else 0
                api.start({ selectionOutlineTransparency = alpha })

                return 2
            end);
        });
        Title = e("TextLabel", {
            Text = setting.name;
            Font = Enum.Font.GothamSemibold;
            TextSize = TITLE_TEXT_SIZE;
            TextColor3 = theme.title;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Bottom;

            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, TITLE_TEXT_SIZE);
            Position = UDim2.new(0, MARGIN, 0, MARGIN);
        });
        Changed = e("TextButton", {
            BackgroundTransparency = 1;
            Size = UDim2.fromOffset(20, 20);
            Position = UDim2.new(1, -20, 0, MARGIN);

            Text = "*";
            TextSize = 40;
            TextYAlignment = Enum.TextYAlignment.Top;
            Font = Enum.Font.GothamBold;
            TextColor3 = theme.highContrast;
            Visible = setting.isChanged;

            ZIndex = 2;

            [Roact.Event.MouseButton1Down] = function()
                props.onSettingCanceled(setting.id)
            end;
        });
        Description = e("TextLabel", {
            Text = setting.description;
            Font = Enum.Font.Gotham;
            TextSize = DESCRIPTION_TEXT_SIZE;
            TextColor3 = theme.text;
            TextYAlignment = Enum.TextYAlignment.Top;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            AutomaticSize = Enum.AutomaticSize.Y;

            Position = UDim2.new(0, MARGIN, 0, TITLE_TEXT_SIZE + MARGIN);
            Size = UDim2.fromOffset(descriptionBounds.X + 1, descriptionBounds.Y + 1);
            BackgroundTransparency = 1;
        });
        Control = control;

        Prompt = prompt;
    })
end

return RoactHooks.new(Roact)(settingEntry)