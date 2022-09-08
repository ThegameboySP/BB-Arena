local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local switch = require(script.Parent.Parent.Presentational.switch)
local percentSlider = require(script.Parent.Parent.Presentational.percentSlider)
local ThemeContext = require(script.Parent.Parent.ThemeContext)

local MARGIN = 6
local TITLE_TEXT_SIZE = 28
local DESCRIPTION_TEXT_SIZE = 24

local function settingEntry(props, hooks)
    local setting = props.setting
    -- The font size shrinks slower than its surrounding text label. Adding an extra line is easy.
    local descriptionBounds = TextService:GetTextSize(setting.description .. "\n", DESCRIPTION_TEXT_SIZE, Enum.Font.Gotham, Vector2.new(682, 1000))
    descriptionBounds = Vector2.new(682, descriptionBounds.Y)

    local theme = hooks.useContext(ThemeContext)
    
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
    })
end

return RoactHooks.new(Roact)(settingEntry)