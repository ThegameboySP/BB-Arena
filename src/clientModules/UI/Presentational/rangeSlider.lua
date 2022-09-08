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
    local range = props.max - props.min

    local sign = props.sign or ""

    return e(slider, Llama.Dictionary.merge(props, {
        value = (props.value - props.min) / range;
        onChanged = function(value)
            props.onChanged(value * range + props.min)
        end;
    }), {
        Range = e("TextBox", {
            [Roact.Ref] = textboxRef;

            AutomaticSize = Enum.AutomaticSize.XY;
            AnchorPoint = Vector2.new(0.5, 1);
            Position = UDim2.new(0.5, 0, 1, 35);

            BackgroundTransparency = 1;
            TextColor3 = theme.title;
            Font = Enum.Font.Gotham;
            TextSize = 28;

            RichText = true;
            Text = string.format([[<font size="18">%d%s —</font> %d%s <font size="18">— %d%s</font>]], props.min, sign, props.value, sign, props.max, sign);

            [Roact.Event.FocusLost] = function(enterPressed)
                if enterPressed then
                    local text = textboxRef:getValue().Text:match("(.+)$")
                    
                    if text and tonumber(text) then
                        local newValue = math.clamp(math.floor(tonumber(text)), props.min, props.max)

                        if newValue ~= props.value then
                            props.onChanged(newValue)
                            return
                        end
                    end

                    textboxRef:getValue().Text = string.format([[<font size="18">%d —</font> %d <font size="18">— %d</font>]], props.min, props.value, props.max)
                end
            end;
        })
    })
end

return RoactHooks.new(Roact)(percentSlider)