local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)

local slider = require(script.Parent.slider)
local ThemeContext = require(script.Parent.Parent.ThemeContext)

local e = Roact.createElement

local function percentSlider(props, hooks)
    local theme = hooks.useContext(ThemeContext)
    local textboxRef = Roact.createRef()

    return e(slider, props, {
        Percentage = e(props.inactive and "TextLabel" or "TextBox", {
            [Roact.Ref] = textboxRef;

            AutomaticSize = Enum.AutomaticSize.XY;
            AnchorPoint = Vector2.new(0.5, 1);
            Position = UDim2.new(0.5, 0, 1, 35);

            BackgroundTransparency = 1;
            TextColor3 = if props.inactive then theme.title:Lerp(theme.inactive, 0.6) else theme.title;
            Font = Enum.Font.Gotham;
            TextSize = 28;

            Text = string.format("%d%%", props.value * 100);

            [Roact.Event.FocusLost] = if props.inactive then nil else function(enterPressed)
                if enterPressed then
                    local text = textboxRef:getValue().Text:match("(.+)%%?$")
                    
                    if text and tonumber(text) then
                        local newValue = math.clamp(math.floor(tonumber(text)) / 100, 0, 1)

                        if newValue ~= props.value then
                            props.onChanged(newValue)
                            return
                        end
                    end

                    textboxRef:getValue().Text = string.format("%d%%", props.value * 100)
                end
            end;
        })
    })
end

return RoactHooks.new(Roact)(percentSlider)