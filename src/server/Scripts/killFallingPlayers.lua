local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local General = require(ReplicatedStorage.Common.Utils.General)

local PLAYER_DIE_BUFFER = 70
local PART_BUFFER = 1_000
local BACKUP_PLAYER_DIE = 1_200
local PART_COUNT = 4

local function createModel(instances)
	local void = Instance.new("Model")
	void.Name = "VoidCollection"

	local pPart = Instance.new("Part")
	pPart.Anchored = true
	pPart.CanCollide = false
	pPart.CanTouch = false
	pPart.CanQuery = false
	void.PrimaryPart = pPart

	for _, instance in instances do
		instance.Parent = void
	end

	return void
end

local function createLayer(y, callback)
	local parts = {}

	for x = 0, PART_COUNT - 1 do
		for z = 0, PART_COUNT - 1 do
			local part = Instance.new("Part")
			part.Size = Vector3.new(2048, 1, 2048)
			part.CFrame = CFrame.new((x - PART_COUNT / 2) * 2048, y, (z - PART_COUNT / 2) * 2048)
			part.Anchored = true
			part.Name = "VoidPart"
			part.CanCollide = false
			part.Transparency = 1

			table.insert(parts, part)

			part.Touched:Connect(callback)
		end
	end

	return createModel(parts)
end

-- There is a Roblox bug where a player can ride a fallen part down to the void, then
-- snap back up once it's destroyed. This is a patch around that.
local function killFallingPlayers(root)
	-- It appears awful character extrapolation will sometimes trick the server into
	-- thinking a character is riding debris on the way down, so the script would kill them
	-- once their Y hit below a plane. So we use .Touched and a Y check backup.
	local void = createModel({
		createLayer(-PLAYER_DIE_BUFFER, function(hit)
			local character = General.getCharacter(hit)
			if character then
				root:KillCharacter(character, GameEnum.DeathCause.Void)
			end
		end),
		createLayer(-PART_BUFFER, function(hit)
			local character = General.getCharacter(hit)

			if character then
				root:KillCharacter(character, GameEnum.DeathCause.Void)
			else
				hit.Parent = nil

				local model = hit:FindFirstAncestorWhichIsA("Model")
				while model do
					if not model:FindFirstChildWhichIsA("BasePart", true) then
						model.Parent = nil
					end

					model = hit:FindFirstAncestorWhichIsA("Model")
				end
			end
		end),
	})

	local backupDieY = -math.huge
	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local head = character and character:FindFirstChild("Head")

			if head and head.Position.Y <= backupDieY then
				root:KillCharacter(character, GameEnum.DeathCause.Void)
			end
		end
	end)

	local function onMapChanged(map)
		local cframe, size = map:GetBoundingBox()
		local y = cframe.Position.Y - size.Y / 2

		backupDieY = y - BACKUP_PLAYER_DIE
		void:PivotTo(CFrame.new(0, y, 0))
		void.Parent = Workspace
	end

	local MapService = root:GetService("MapService")

	MapService.MapChanged:Connect(onMapChanged)
	if MapService.CurrentMap then
		onMapChanged(MapService.CurrentMap)
	end
end

return killFallingPlayers
