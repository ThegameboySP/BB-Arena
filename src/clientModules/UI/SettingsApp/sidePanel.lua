local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local e = Roact.createElement

local function sidePanel(props)
    local children = {}
    for i, settingCategory in ipairs(props.settingCategories) do
        children[string.char(i)] = e("ImageButton", {
            Size = props.iconSize;
            Image = settingCategory.imageId;
            BackgroundTransparency = 1;

            [Roact.Event.MouseButton1Down] = function()
                props.onPressed(settingCategory)
            end
        })
    end

    children.UIlistLayout = e("UIListLayout", {
        Padding = UDim.new(0, 30);
        
        FillDirection = Enum.FillDirection.Vertical;
        HorizontalAlignment = Enum.HorizontalAlignment.Center;
        SortOrder = Enum.SortOrder.Name;
        VerticalAlignment = Enum.VerticalAlignment.Top;
    })

    return e("Frame", {
        AnchorPoint = Vector2.new(0, 0);
        Size = props.size;
        BackgroundTransparency = 1;
    }, {
        e("Frame", {
            Size = UDim2.fromScale(1, 1);
            BackgroundTransparency = 1;
        }, {
            SideBar = e("Frame", {
                AnchorPoint = Vector2.new(1, 0);
                Size = UDim2.new(0, 4, 1, 0);
                Position = UDim2.new(1, 4, 0, 0);
    
                BackgroundColor3 = props.dividerColor;
                BorderSizePixel = 0;
                BackgroundTransparency = 0;
            });
            List = e("Frame", {
                Position = UDim2.new(0, 0, 0, 0);
                Size = UDim2.new(1, 0, 1, 0);
                BackgroundTransparency = 1;
            }, children)
        })
    })
end

return sidePanel