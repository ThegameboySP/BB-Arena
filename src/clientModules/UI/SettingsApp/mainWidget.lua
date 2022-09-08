local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local AutoUIScale = require(script.Parent.Parent.AutoUIScale)
local button = require(script.Parent.Parent.Presentational.button)
local sidePanel = require(script.Parent.sidePanel)
local contents = require(script.Parent.contents)
local draggable = require(script.Parent.Parent.draggable)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local SIDE_BAR_LENGTH = 4

local function mainWidget(props, hooks)
	local categoryBinding, setCategory = hooks.useBinding(props.settingCategories[1])
	local theme = hooks.useContext(ThemeContext)
	local value = hooks.useValue()

	value.topRef = value.topRef or Roact.createRef()
	value.rootRef = value.rootRef or Roact.createRef()
	
	local selectEvent = Instance.new("BindableEvent")

	return e("Frame", {
		BackgroundTransparency = 1;
		Size = UDim2.fromScale(1, 1);
	}, {
		Frame = e("ImageLabel", {
			[Roact.Ref] = value.rootRef;
			
			BackgroundTransparency = 1;
			
			ImageColor3 = theme.background;
			Image = "rbxassetid://9264310289";
			ScaleType = Enum.ScaleType.Slice;
			SliceCenter = Rect.new(Vector2.new(128, 128), Vector2.new(128, 128));
			SliceScale = 0.1;
			
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 1000, 0, 700 - 60)
		}, {
			UIScale = e(AutoUIScale, {
				minScaleRatio = 0.5;
			});
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 2;
			});
			Top = e(draggable, {
				topRef = value.topRef;
				rootRef = value.rootRef;

				position = UDim2.new(0, 0, 0, -60);
				size = UDim2.new(1, 0, 0, 60)
			}, {
				Title = e("ImageLabel", {
					[Roact.Ref] = value.topRef;

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
						Image = "rbxassetid://9206592117";
						BackgroundTransparency = 1;

						Size = UDim2.fromOffset(50, 50);
						AnchorPoint = Vector2.new(0, 0.5);
						Position = UDim2.new(0, 10, 0.5, 0);
					});

					TextLabel = e("TextLabel", {
						Text = "Settings";
						Font = Enum.Font.GothamBold;
						TextColor3 = theme.title;
						TextSize = 38;
						TextXAlignment = Enum.TextXAlignment.Left;

						BackgroundTransparency = 1;
						Size = UDim2.fromScale(1, 1);
						Position = UDim2.new(0, 50 + 10 + 10, 0, 0);
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
			PanelContainer = e("Frame", {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 0, 0, 20);
				Size = UDim2.new(1, 0, 1, -20);
			}, {
				Panel = e(sidePanel, {
					size = UDim2.new(0, 100, 1, 0);
					iconSize = UDim2.fromOffset(80, 80);
					dividerColor = theme.border;
					
					settingCategories = props.settingCategories;
					onPressed = function(category)
						setCategory(category)
						selectEvent:Fire(function()
							return category
						end)
					end;
				});
			});

			ContentsContainer = e("ImageLabel", {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 100 + SIDE_BAR_LENGTH, 0, 20);
				Size = UDim2.new(1, -100 - SIDE_BAR_LENGTH, 1, -100);

				Image = "rbxassetid://rbxassetid://10848356902";
			}, {
				Contents = e(contents, {
					settings = props.settingRecords;
					categories = props.settingCategories;
					changedSettings = props.changedSettings;

					onSettingChanged = props.onSettingChanged;
					onSettingCanceled = props.onSettingCanceled;

					categoryBinding = categoryBinding;
					selectEvent = selectEvent.Event;

					onCategoryChanged = function(category)
						setCategory(category)
					end;
				});
			});

			Save = e(button, {
				position = UDim2.new(0.86, 0, 1, -10);
				anchor = Vector2.new(0.5, 1);
				text = "Save settings";
				color = theme.button;
				textColor = theme.highContrast;
				onPressed = function()
					props.onSettingsSaved()
				end;
			});

			Defaults = e(button, {
				position = UDim2.new(0.86, -220, 1, -10);
				anchor = Vector2.new(0.5, 1);
				text = "Restore defaults";
				color = theme.lessImportantButton;
				textColor = theme.highContrast;
				onPressed = function()
					props.onRestoreDefaults()
				end;
			});
		});
	})
end

return RoactHooks.new(Roact)(mainWidget)