local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local switch = require(script.Parent.Parent.Presentational.switch)
local percentSlider = require(script.Parent.Parent.Presentational.percentSlider)
local rangeSlider = require(script.Parent.Parent.Presentational.rangeSlider)
local list = require(script.Parent.Parent.Presentational.list)
local button = require(script.Parent.Parent.Presentational.button)
local window = require(script.Parent.Parent.Presentational.window)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local Container = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

local MARGIN = 6
local TITLE_TEXT_SIZE = 28
local DESCRIPTION_TEXT_SIZE = 24

local function modal(props, hooks)
    local self = hooks.useValue()
    self.outerRef = self.outerRef or Roact.createRef()

    return e(Roact.Portal, {
        target = Container
    }, {
        Modal = e("ScreenGui", {
            [Roact.Ref] = self.outerRef;

            ResetOnSpawn = false;
        }, {
            Window = e(window, {
                size = UDim2.fromOffset(800, 400);
                aspectRatio = 1;
                name = props.name;
                outerRef = self.outerRef;

                useExitButton = false;

                onClosed = function()
                    props.onFinished(false)
                end;
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
        })
    })
end

modal = RoactHooks.new(Roact)(modal)

local function settingEntry(props, hooks)
    local setting = props.setting
    -- The font size shrinks slower than its surrounding text label. Adding an extra line is easy.
    local descriptionBounds = TextService:GetTextSize(setting.description .. "\n", DESCRIPTION_TEXT_SIZE, Enum.Font.Gotham, Vector2.new(682, 1000))
    descriptionBounds = Vector2.new(682, descriptionBounds.Y)

    local theme = hooks.useContext(ThemeContext)
    local isPrompting, setIsPrompting = hooks.useState(false)
    local keybindCallback, setKeybindCallback = hooks.useState(nil)

    hooks.useEffect(function()
        if keybindCallback then
            local connection
            connection = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then
                    return
                end

                if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
                    keybindCallback.callback(input.KeyCode)
                end
            end)

            return function()
                connection:Disconnect()
            end
        end
    end)
    
    local prompt = nil

    if isPrompting then
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
            onFinished = function()
                props.onPrompt(false)
                setIsPrompting(false)
            end;
        })
    end

    local control
    if setting.type == "switch" then
        control = e(switch, {
            value = setting.value;
            anchor = Vector2.new(1, 0.5);
            position = UDim2.new(1, -10, 0.5, 0);
            onChanged = function()
                props.onSettingChanged(setting.id, not setting.value)
            end;
        })
    elseif setting.type == "slider" then
        control = e(percentSlider, {
            value = setting.value;
            anchor = Vector2.new(1, 0.5);
            position = UDim2.new(1, -10, 0.5, 0);
            onChanged = function(percent)
                props.onSettingChanged(setting.id, percent)
            end;
        })
    elseif setting.type == "range" then
        control = e(rangeSlider, {
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
            position = UDim2.new(1, -10, 0.5, 0);
            anchor = Vector2.new(1, 0.5);
            text = string.format("Press for list...\n%q", tostring(setting.value));
            color = theme.background;
            textColor = theme.text;
            textSize = 20;

            onPressed = function()
                props.onPrompt(true)
                setIsPrompting(true)
            end;
        })
    elseif setting.type == "keybind" then
        control = e(button, {
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
                        props.onSettingChanged(setting.id, keycode.Name)
                    end;
                })
            end;
        })
    end

    return e("Frame", {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 0, descriptionBounds.Y + 1 + TITLE_TEXT_SIZE + MARGIN + MARGIN);
    }, {
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