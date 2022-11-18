local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local e = Roact.createElement

local blendAlpha = require(script.Parent.Parent.Utils.blendAlpha)

local function thumbnail(props, hooks)
	local staticRef = hooks.useBinding()
	local thumbnailRef = hooks.useBinding()
    local styles, api = RoactSpring.useSpring(hooks, function()
        return { static = 1, transparency = 0, blendThumbnails = 0 }
    end)
    local lastThumbnail = hooks.useValue(props.thumbnail)

    hooks.useEffect(function()
        if lastThumbnail.value ~= props.thumbnail then
            lastThumbnail.value = props.thumbnail

            api.start({
                from = { blendThumbnails = 0 },
                to = { blendThumbnails = 1 },
                config = { tension = if props.thumbnail then 50 else 100 },
            })
        end

        if props.isFull then
            api.start({
                from = { static = 0 },
                to = { static = 1} ,
                config = { tension = 180, friction = 8, bounce = 1.5 },
            })
        end

        api.start({
            transparency = if props.isFull then 1 else 0,
            config = { tension = 250, clamp = true }
        })
    end)

	hooks.useEffect(function()
        local random = Random.new()
		local thread = task.spawn(function()
			while true do
				staticRef:getValue().ImageRectOffset = Vector2.new(
                    random:NextInteger(0, 1024),
                    random:NextInteger(0, 1024)
                )
        
                task.wait(1/15)	
			end
		end)

		local started = os.clock()
		local PERIOD = (math.pi * 2) / 8
		local connection = RunService.Heartbeat:Connect(function()
			thumbnailRef:getValue().Position = UDim2.new(
				0.5, 0,
				0.5, math.sin((os.clock() - started) * PERIOD) * 8
			)
		end)

		return function()
			coroutine.close(thread)
			connection:Disconnect()
		end
	end, {})

    local blendedAlpha = Roact.joinBindings({
        transparency = styles.transparency:map(function(value)
            return 0.8 * (1 - value)
        end);
        blendThumbnails = styles.blendThumbnails;
    })

	return e("TextButton", {
        Active = true;
        ClipsDescendants = true;

        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.new(0.5, 0, 0.5, 0);
        Size = props.size;

        Text = "";
        BackgroundTransparency = 1;
        ZIndex = props.zIndex;

        [Roact.Event.Activated] = function()
            if props.thumbnail then
                props.onFullChanged(not props.isFull)
            end
        end;
    }, {
        Coverup = e("Frame", {
            Size = UDim2.new(1, 0, 1, 0);
            BorderSizePixel = 0;
            BackgroundColor3 = Color3.fromRGB(0, 0, 0);
            BackgroundTransparency = styles.transparency:map(function(value)
                return 1 - value
            end);
            ZIndex = -1;
        });
        Thumbnail = e("ImageLabel", {
            [Roact.Ref] = thumbnailRef;

            Size = UDim2.new(1, 40, 1, 40);
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.new(0.5, 0, 0.5, 0);

            Image = lastThumbnail.value;
            ImageTransparency = blendedAlpha:map(function(values)
                return blendAlpha({ values.transparency, values.blendThumbnails })
            end);
            BackgroundTransparency = 1;
        }, {
            BlendThumbnail = e("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0);
                Image = props.thumbnail;
                ImageTransparency = blendedAlpha:map(function(values)
                    return blendAlpha({ values.transparency, 1 - values.blendThumbnails })
                end);
                BackgroundTransparency = 1;
            });
            Static = e("ImageLabel", {
                [Roact.Ref] = staticRef;
    
                Visible = props.thumbnail ~= nil;
                
                AnchorPoint = Vector2.new(0.5, 0.5);
                Position = UDim2.new(0.5, 0, 0.5, 0);
                Size = UDim2.new(1, 0, 1, 0);
    
                Image = "rbxassetid://268592485";
                BackgroundTransparency = 1;
                ZIndex = 3;
                ImageTransparency = styles.static:map(function(value)
                    return 0.8 - (1 - value) * 0.9
                end);
    
                ImageRectSize = Vector2.new(1024, 1024);
            })
        });
    });
end

return RoactHooks.new(Roact)(thumbnail)