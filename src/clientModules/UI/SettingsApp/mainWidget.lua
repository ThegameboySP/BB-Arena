local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local button = require(script.Parent.Parent.Presentational.button)
local sidePanel = require(script.Parent.sidePanel)
local contents = require(script.Parent.contents)
local window = require(script.Parent.Parent.Presentational.window)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local SIDE_BAR_LENGTH = 4

local function mainWidget(props, hooks)
	local categoryBinding, setCategory = hooks.useBinding(props.settingCategories[1])
	local isActiveBinding, setIsActive = hooks.useBinding(true)

	local theme = hooks.useContext(ThemeContext)
	local value = hooks.useValue()

	value.outerRef = value.outerRef or Roact.createRef()
	
	local selectEvent = Instance.new("BindableEvent")

	return e("Frame", {
		[Roact.Ref] = value.outerRef;

		BackgroundTransparency = 1;
		Size = UDim2.fromScale(1, 1);

		Visible = isActiveBinding:map(function(isActive)
			return isActive
		end);
	}, {
		Window = e(window, {
			size = UDim2.new(0, 1000, 0, 700 - 60);
			aspectRatio = 2;
			image = "rbxassetid://9206592117";
			imageSize = Vector2.new(50, 50);
			name = "Settings";
			useExitButton = true;

			outerRef = value.outerRef;
			
			onClosed = props.onClosed;
		}, {
			PanelContainer = e("Frame", {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 0, 0, 20);
				Size = UDim2.new(1, 0, 1, -20);
			}, {
				Panel = e(sidePanel, {
					size = UDim2.new(0, 100, 1, 0);
					iconSize = UDim2.fromOffset(80, 80);
					dividerColor = theme.border;
					activeCategory = categoryBinding;
					
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

					onPrompt = function(isPrompting)
						setIsActive(not isPrompting)
					end;
				});
			});

			Save = e(button, {
				position = UDim2.new(0.86, 0, 1, -10);
				anchor = Vector2.new(0.5, 1);
				text = "Save settings";
				textSize = 28;
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
				textSize = 28;
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