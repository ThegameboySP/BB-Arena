local function randomDirection(random)
	local degrees = math.rad(random:NextNumber(230, 310))
	return Vector3.new(math.cos(degrees), -math.sin(degrees), 0)
end

local template = script.SnowflakeTemplate
local function newSnowflake(random)
	local clone = template:Clone()
	-- random size
	local radius = random:NextNumber(4, 10)
	clone.Snowflake.Size = UDim2.new(0, radius, 0, radius)

	-- clone.BackgroundTransparency = 0.6
	-- clone.BackgroundColor3 = Color3.new(0, 1, 0)

	-- depth
	local scale = (radius - 4) / 6
	clone.Snowflake.ImageTransparency = 0.6 * (1 - scale)

	-- offset
	local direction = randomDirection(random)
	clone.Snowflake.AnchorPoint = Vector2.new(0.5, 0.5)
	local add = direction * 0.5
	clone.Snowflake.Position = UDim2.fromScale(0.5 + add.X, 0.5 + add.Y)

	return clone, scale, direction
end

local Snowfall = {}
Snowfall.__index = Snowfall

function Snowfall.new(target, yCutoff)
	return setmetatable({
		target = target,
		yCutoff = yCutoff,

		flakes = {},
		random = Random.new(),
		lastSpawned = 0,
	}, Snowfall)
end

function Snowfall:Destroy()
	for flake in self.flakes do
		flake.Parent = nil
	end
end

function Snowfall:Update(dt)
	local now = os.clock()

	if (now - self.lastSpawned) > 1 / 30 then
		local newFlake, scale, direction = newSnowflake(self.random)
		newFlake.Parent = self.target

		local small = 1 - scale

		self.flakes[newFlake] = {
			xPercent = self.random:NextNumber(),
			direction = direction,
			speed = math.clamp(scale + 0.2, 0, 1) * self.random:NextNumber(2, 4) * 60,
			spawnedOn = now,
			--[[0.2]]
			offset = 120 * 0.4 * self.random:NextNumber(0, 3.5) * self.random:NextNumber(0.8, 1),
			period = (math.pi * 2) / (1 * self.random:NextNumber(1, 2)),
			inactive = (math.pi * 2) / (self.random:NextNumber(8, 10) * small),
			position = Vector3.yAxis * -12,
		}

		self.lastSpawned = now
	end

	for flake, data in self.flakes do
		if data.position.Y > self.yCutoff then
			flake.Parent = nil
			self.flakes[flake] = nil
			continue
		end

		data.position += data.direction * data.speed * dt

		flake.Position = UDim2.new(data.xPercent, data.position.X, 0, data.position.Y)

		flake.Rotation += dt * data.offset * math.sin((now - data.spawnedOn) * data.period) * math.cos(
			(now - data.spawnedOn) * data.inactive
		)
	end
end

return Snowfall
