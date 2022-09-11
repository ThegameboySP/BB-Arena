local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local AutoUIScale = require(script.Parent.Parent.AutoUIScale)
local button = require(script.Parent.Parent.Presentational.button)
local draggable = require(script.Parent.Parent.draggable)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local columns = {
    "Map name",
    "Teams",
    "Neutral allowed",
    "CTF",
    "Control Points",
    "Size",
	"Creator"
}

local booleanSort = function(a, b)
    return a.sortingColumn == "yes" and b.sortingColumn == "no"
end

local reverseBooleanSort = function(a, b)
	return a.sortingColumn == "no" and b.sortingColumn == "yes"
end

local defaultSort = function(a, b)
    return a.sortingColumn < b.sortingColumn
end

local reverseDefaultSort = function(a, b)
	return a.sortingColumn > b.sortingColumn
end

local sizeSort = function(a, b)
	local ax, az = a.sortingColumn:match("(%d+)x(%d+)")
	local bx, bz = b.sortingColumn:match("(%d+)x(%d+)")

	return (ax * az) > (bx * bz)
end

local reverseSizeSort = function(a, b)
	local ax, az = a.sortingColumn:match("(%d+)x(%d+)")
	local bx, bz = b.sortingColumn:match("(%d+)x(%d+)")

	return (ax * az) < (bx * bz)
end

local reverseSorts = {
	[booleanSort] = reverseBooleanSort;
	[defaultSort] = reverseDefaultSort;
	[sizeSort] = reverseSizeSort;
}

local sortingMethods = {
    ["Neutral allowed"] = booleanSort;
    ["CTF"] = booleanSort;
    ["Control Points"] = booleanSort;
	["Size"] = sizeSort;
}

local PADDING_Y = 10

local function mapListWidget(props, hooks)
	local theme = hooks.useContext(ThemeContext)
	local values = hooks.useValue()

    local sortBy, setSortBy = hooks.useState("Map name")
	local reversed, setReversed = hooks.useState(false)
	local selected, setSelected = hooks.useState(nil)

	if not next(values) then
		values.topRef = Roact.createRef()
		values.rootRef = Roact.createRef()
	end
	
	local outputTextBinding, setOutputText = hooks.useBinding("")

    local rowElements = {}
	local headerRowElements = {}

	local yContents = 0
	for i, column in columns do
		local textBounds = TextService:GetTextSize(column, 24, Enum.Font.GothamBold, Vector2.new(200, 200))
		yContents = math.max(yContents, textBounds.Y)

		table.insert(headerRowElements, e("TextButton", {
            BackgroundTransparency = 1;

            Font = Enum.Font.GothamBold;
            Text = column;
            TextSize = 24;
            TextColor3 = theme.text;
            TextXAlignment = if i == 1 then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center;
            TextYAlignment = Enum.TextYAlignment.Top;

            Size = UDim2.fromOffset(textBounds.X, textBounds.Y);

            [Roact.Event.MouseButton1Down] = function()
				if sortBy == column then
					setReversed(not reversed)
				else
                	setSortBy(column)
					setReversed(false)
				end
            end;
        }))
	end

	table.insert(rowElements, e("Frame", {
		BackgroundTransparency = 1;
		Size = UDim2.fromOffset(300, 200);
	}, headerRowElements))

	local rowValues = {}
	for _, mapInfo in props.mapInfo do
		table.insert(rowValues, {
			sortingColumn = mapInfo[sortBy];
			mapInfo = mapInfo;
		})
	end

	if reversed then
		local sortingMethod = sortingMethods[sortBy] or defaultSort
		table.sort(rowValues, reverseSorts[sortingMethod])
	else
		table.sort(rowValues, sortingMethods[sortBy] or defaultSort)
	end

	for _, entry in rowValues do
		local nextRowElements = {}
		local maxY = 0

		for i, column in columns do
			local value = entry.mapInfo[column]

			local str = tostring(value)

			local textBounds = TextService:GetTextSize(str, 20, Enum.Font.Gotham, Vector2.new(190, 500))
			maxY = math.max(maxY, textBounds.Y)

			table.insert(nextRowElements, e("TextLabel", {
				BackgroundTransparency = 1;

				Font = Enum.Font.Gotham;
				Text = (if i == 1 then " " else "") .. str;
				TextSize = 20;
				TextWrapped = true;
				TextColor3 = theme.text;
				TextXAlignment = if i == 1 then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center;
				TextYAlignment = Enum.TextYAlignment.Center;

				Size = UDim2.fromOffset(textBounds.X, textBounds.Y);
			}))
		end

		yContents += maxY + PADDING_Y*2 

		local isActive = props.activeMap == entry.mapInfo["Map name"]
		local isSelected = selected == entry.mapInfo["Map name"]

		table.insert(rowElements, e("TextButton", {
			BackgroundTransparency = 0.6;
			BackgroundColor3 = if isSelected then theme.accent elseif isActive then theme.text else theme.foreground;
			Text = "";

			[Roact.Event.MouseButton1Down] = function()
				setSelected(entry.mapInfo["Map name"])
			end;
		}, nextRowElements))

		table.insert(rowElements, e("Frame", {
			Size = UDim2.new(0.1, 0, 0, 100);
			BorderColor3 = theme.border;
		}))
	end

	local rowElementsMap = {}
	for i, element in rowElements do
		rowElementsMap[string.char(i)] = element
	end

	hooks.useEffect(function()
		-- Sometimes cells are improperly sized in UITableLayout. This is essentially a hack to get :ApplyLayout.
		local root = values.rootRef:getValue()
		local scrollingFrame = root:FindFirstChild("ContentsContainer")

		for _, child in scrollingFrame:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = false
			end
		end

		local _ = scrollingFrame:FindFirstChild("UITableLayout").AbsoluteContentSize

		for _, child in scrollingFrame:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = true
			end
		end
	end)

	return e("Frame", {
		BackgroundTransparency = 1;
		Size = UDim2.fromScale(1, 1);
	}, {
		Frame = e("ImageLabel", {
			[Roact.Ref] = values.rootRef;
			
			BackgroundTransparency = 1;
			
			ImageColor3 = theme.background;
			Image = "rbxassetid://9264310289";
			ScaleType = Enum.ScaleType.Slice;
			SliceCenter = Rect.new(Vector2.new(128, 128), Vector2.new(128, 128));
			SliceScale = 0.1;
			
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 1100, 0, 700)
		}, {
			UIScale = e(AutoUIScale, {
				minScaleRatio = 0.5;
			});
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 2;
			});
			Top = e(draggable, {
				topRef = values.topRef;
				rootRef = values.rootRef;

				position = UDim2.new(0, 0, 0, -60);
				size = UDim2.new(1, 0, 0, 60)
			}, {
				Title = e("ImageLabel", {
					[Roact.Ref] = values.topRef;

					ImageColor3 = theme.foreground;
					Image = "rbxassetid://9264443152";
					ScaleType = Enum.ScaleType.Slice;
					SliceCenter = Rect.new(Vector2.new(128, 128), Vector2.new(128, 128));
					SliceScale = 0.1;
					
					BorderSizePixel = 0;
					Position = UDim2.new(0, 0, 0, 0);
					Size = UDim2.fromScale(1, 1);
					BackgroundTransparency = 1;
				}, {
					Icon = e("ImageLabel", {
						Image = "rbxassetid://10866961648";
						BackgroundTransparency = 1;

						Size = UDim2.fromOffset(63, 50);
						AnchorPoint = Vector2.new(0, 0.5);
						Position = UDim2.new(0, 10, 0.5, 0);
					});

					TextLabel = e("TextLabel", {
						Text = "Map list";
						Font = Enum.Font.GothamBold;
						TextColor3 = theme.title;
						TextSize = 38;
						TextXAlignment = Enum.TextXAlignment.Left;

						BackgroundTransparency = 1;
						Size = UDim2.fromScale(1, 1);
						Position = UDim2.new(0, 85, 0, 0);
					});

					Close = e("ImageButton", {
						BackgroundTransparency = 1;

						AnchorPoint = Vector2.new(1, 0.5);
						Position = UDim2.new(1, -5, 0.5, 0);
						Size = UDim2.new(0, 50, 0, 50);
						Image = "http://www.roblox.com/asset/?id=5107150301";

						[Roact.Event.MouseButton1Down] = function()
							props.onClosed()
						end;
					});
				})
			});

			ContentsContainer = e("ScrollingFrame", {
				BackgroundTransparency = 0;
				BackgroundColor3 = theme.foreground;
				ScrollBarImageColor3 = theme.scrollbar;
				BorderSizePixel = 0;
				ScrollBarThickness = 12;

				Position = UDim2.new(0, 20, 0, 20);
				Size = UDim2.new(1, -40, 0, 380);
				CanvasSize = UDim2.fromOffset(0, yContents);

			}, Llama.Dictionary.merge({
				UITableLayout = e("UITableLayout", {
                    Padding = UDim2.fromOffset(20, PADDING_Y);
                    MajorAxis = Enum.TableMajorAxis.RowMajor;
					HorizontalAlignment = Enum.HorizontalAlignment.Center;
                });
			}, rowElementsMap));

			ChangeMap = e(button, {
				text = "Change to selected map";
				position = UDim2.new(0.5, 0, 0, 425);
				anchor = Vector2.new(0.5, 0);
				color = theme.lessImportantButton;
				textColor = theme.title;

				onPressed = function()
					if selected then
						setOutputText(props.changeToMap(selected))
					end
				end;
			});

			OutputContainer = e("Frame", {
				Visible = true;
				BackgroundTransparency = 1;
				ClipsDescendants = true;

				Size = UDim2.new(1, -30, 0, 50);
				AnchorPoint = Vector2.new(0.5, 1);
				Position = UDim2.new(0.5, 0, 1, 0);
			}, {
				Output = e("ImageLabel", {
					ImageColor3 = theme.foreground;
					Image = "rbxassetid://9264443152";
					ScaleType = Enum.ScaleType.Slice;
					SliceCenter = Rect.new(Vector2.new(128, 128), Vector2.new(128, 128));
					SliceScale = 0.1;
					
					BorderSizePixel = 0;
					Size = UDim2.new(1, 0, 1, 0);
					AnchorPoint = Vector2.new(0.5, 1);
					Position = UDim2.new(0.5, 0, 1, 0);
					BackgroundTransparency = 1;
				}, {
					TextLabel = e("TextLabel", {
						BackgroundTransparency = 1;

						Size = UDim2.fromScale(1, 1);
						Position = UDim2.new(0, 0, 0, 0);
	
						Text = outputTextBinding;
						TextSize = 28;
						Font = Enum.Font.GothamSemibold;
						TextColor3 = theme.text;
					});
				});
			})
		});
	})
end

return RoactHooks.new(Roact)(mapListWidget)