local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local settingEntry = require(script.Parent.settingEntry)
local ThemeContext = require(script.Parent.Parent.ThemeContext)

local CATEGORY_LABEL_TEXT_SIZE = 32

local function settingCategory(props, hooks)
    local self = hooks.useValue()
    if not next(self) then
        self.listRef = Roact.createRef()
        self.contentsY, self.setContentsY = Roact.createBinding(0)
    end

    hooks.useEffect(function()
        self.setContentsY(self.listRef:getValue().AbsoluteContentSize.Y)
    end, self)

    local theme = hooks.useContext(ThemeContext)

    local children = {}
    local i = 0
    for index, setting in ipairs(props.settings) do
        children[string.char(i)] = e(settingEntry, {
            setting = setting;
            onSettingChanged = props.onSettingChanged;
            onSettingCanceled = props.onSettingCanceled;
            onPrompt = props.onPrompt;
        })

        if not props.settings[index + 1] then
            break
        end

        children[string.char(i + 1)] = e("Frame", {
            Size = UDim2.new(1, 0, 0, 2);

            BackgroundColor3 = theme.border;
            BorderSizePixel = 0;
            BackgroundTransparency = 0;
        });
        
        i += 2
    end

    children.UIListLayout = e("UIListLayout", {
        [Roact.Ref] = self.listRef;
        Padding = UDim.new(0, 2);
    })

    children.UIStroke = e("UIStroke", {
        Color = theme.border;
        Thickness = 1;
    })

    children.UICorner = e("UICorner", {
        CornerRadius = UDim.new(0, 5);
    })

    return e("Frame", {
        BackgroundTransparency = 1;
        Size = self.contentsY:map(function(contentsY)
            return UDim2.new(1, 0, 0, contentsY + 6 + CATEGORY_LABEL_TEXT_SIZE + 10);
        end);
    }, {
        CategoryImage = e("ImageLabel", {
            BackgroundTransparency = 1;

            Size = UDim2.new(0, 35, 0, 35);
            Image = props.category.imageId;
            Position = UDim2.new(0, 0, 0, 0);
        });
        CategoryLabel = e("TextLabel", {
            BackgroundTransparency = 1;

            Size = UDim2.new(1, 0, 0, CATEGORY_LABEL_TEXT_SIZE);
            Position = UDim2.new(0, 35 + 8, 0, 0);

            TextColor3 = theme.title;
            TextXAlignment = Enum.TextXAlignment.Left;
            Text = props.category.name;
            TextSize = CATEGORY_LABEL_TEXT_SIZE;
            Font = Enum.Font.GothamSemibold;
        });
        Background = e("Frame", {
            BorderSizePixel = 0;
            BackgroundColor3 = theme.foreground;
            Position = UDim2.new(0, 0, 0, CATEGORY_LABEL_TEXT_SIZE + 10);
            Size = UDim2.new(1, 0, 1, -(CATEGORY_LABEL_TEXT_SIZE + 10));
        }, children)
    })
end

return RoactHooks.new(Roact)(settingCategory)