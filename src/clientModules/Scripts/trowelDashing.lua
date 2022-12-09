local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Effects = require(ReplicatedStorage.Common.Utils.Effects)

local LocalPlayer = Players.LocalPlayer

local trowelFilter = Effects.pipe({
	Effects.children,
	Effects.childrenFilter(function(child)
		return child.Name:find("Wall") ~= nil
	end),
})

local projFilter = Effects.pipe({
	Effects.children,
	Effects.children,
	function(proj, add)
		if not proj:IsA("BasePart") then
			return
		end
		if not proj.Name:find("Bomb") then
			return
		end

		add(proj)
	end,
	function(proj, add)
		local function onChildAdded(child)
			if child.Name == "creator" and child.Value == LocalPlayer then
				add(proj)
			end
		end

		local creator = proj:FindFirstChild("creator")
		if creator then
			onChildAdded(creator)
		end

		local con = proj.ChildAdded:Connect(onChildAdded)
		return function()
			con:Disconnect()
		end
	end,
})

--local function getGreatestSide(size)
--	local max = math.max(size.X, size.Y, size.Z)
--	if max == size.X then
--		return Vector3.xAxis * max
--	elseif max == size.Y then
--		return Vector3.yAxis * max
--	elseif max == size.Z then
--		return Vector3.zAxis * max
--	end
--end

local function isAbove(point, planePoint, normal)
	return (point - planePoint):Dot(normal) > 0
end

local function getSide(headPos, CF, size)
	local side = Vector3.new(size.X / 2, 0, 0)

	local min = CF:PointToWorldSpace(-side)
	local max = CF:PointToWorldSpace(side)
	local n = CF:VectorToWorldSpace(side.Unit)

	if isAbove(headPos, min, -n) then
		return min, max, -n
	elseif isAbove(headPos, max, n) then
		return max, min, n
	end
end

local function isBrick(model)
	return model.Parent.Name:find("Wall")
end

local function getLength(brick, oDir, wDir, CF)
	-- If this brick isn't aligned to the direction, stop here.
	local xDir = brick.CFrame.RightVector
	if math.abs(wDir:Dot(xDir)) > 0.1 then
		print("unaligned")
		return 0
	end

	local sizeVec = brick.Size * oDir
	local wSizeVec = CF:VectorToWorldSpace(sizeVec)
	local result = workspace:Raycast(brick.Position + wSizeVec / 2 - wSizeVec * 0.01, wSizeVec * 0.1)
	local length = wSizeVec.Magnitude

	if result == nil then
		return length
	end

	if isBrick(result.Instance) then
		return getLength(result.Instance, oDir, wDir, CF) + length
	end

	return length
end

local function point(pos)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.05, 0.05, 0.05)
	part.CFrame = CFrame.new(pos)
	part.Material = Enum.Material.Neon
	part.Parent = workspace
end

local function getContigousBricks(brick, dir, bricks)
	bricks = bricks or {}
	table.insert(bricks, brick)

	local nextSide = workspace:Raycast(brick.Position + dir * (brick.Size.X / 2 - 0.01), dir * 0.2)

	if nextSide and isBrick(nextSide.Instance) then
		return getContigousBricks(nextSide.Instance, dir, bricks)
	end

	return bricks
end

local function getSize(trowel, playerPos, trowelCF)
	local bottomRow = {}

	for _, child in pairs(trowel:GetChildren()) do
		if not child:IsA("BasePart") then
			continue
		end

		local bottom =
			workspace:Raycast(child.Position + Vector3.new(0, -child.Size.Y / 2 + 0.01, 0), Vector3.new(0, -0.8, 0))

		local top =
			workspace:Raycast(child.Position + Vector3.new(0, child.Size.Y / 2 - 0.01, 0), Vector3.new(0, 0.8, 0))

		if top and isBrick(top.Instance) and bottom and not isBrick(bottom.Instance) then
			table.insert(bottomRow, child)
		end
	end

	if bottomRow[1] == nil then
		return Vector3.zero, trowelCF
	end

	table.sort(bottomRow, function(a, b)
		return (a.Position - playerPos).Magnitude < (b.Position - playerPos).Magnitude
	end)

	local isOnRight = isAbove(playerPos, trowelCF.Position, trowelCF.RightVector)
	local awaySign = isOnRight and -1 or 1
	local bottomRowContiguous = getContigousBricks(bottomRow[1], awaySign * trowelCF.RightVector)

	if bottomRowContiguous[1] == nil then
		return Vector3.zero, trowelCF
	end

	local totalHeight
	local totalWidth = 0
	for _, brick in ipairs(bottomRowContiguous) do
		local height = getLength(brick, Vector3.yAxis, trowelCF:VectorToWorldSpace(Vector3.yAxis), trowelCF)
		totalHeight = math.min(totalHeight or math.huge, height)

		totalWidth += (brick.Size * Vector3.xAxis).Magnitude
	end

	local size = Vector3.new(totalWidth, totalHeight or 0, 2)
	local center = bottomRowContiguous[1].Position
		+ trowelCF:VectorToWorldSpace(bottomRowContiguous[1].Size / 2 * Vector3.new(-awaySign, -1, 0))
		+ trowelCF:VectorToWorldSpace(Vector3.new(awaySign, 1, 0) * size / 2)

	return size, CFrame.lookAt(center, center + trowelCF.LookVector)
end

local findTrowelParams = OverlapParams.new()
findTrowelParams.FilterType = Enum.RaycastFilterType.Whitelist
findTrowelParams.MaxParts = math.huge

local findPlayerParams = OverlapParams.new()
findPlayerParams.FilterType = Enum.RaycastFilterType.Whitelist
findPlayerParams.MaxParts = 1

local MAX_DIST = 12
local WIGGLE = 8

local MAX_DIST_EXPLOSION = 12
local WIGGLE_EXPLOSION = 8

local TROWEL_LENGTH = 12

local function trowelDashing(Root)
	local collisionPart = Instance.new("Part")

	local trowels = {}

	trowelFilter(workspace:WaitForChild("Projectiles"):WaitForChild("Active"), function(trowel)
		table.insert(trowels, trowel)
		findTrowelParams.FilterDescendantsInstances = { unpack(trowels) }
	end, function(trowel)
		local index = table.find(trowels, trowel)
		if index then
			table.remove(trowels, index)
			findTrowelParams.FilterDescendantsInstances = { unpack(trowels) }
		end
	end)

	projFilter(workspace:WaitForChild("Projectiles"):WaitForChild("Active"), function(proj)
		local projectileTbl = setmetatable({ proj }, { __mode = "v" })

		proj:GetPropertyChangedSignal("Name"):Connect(function()
			local exploded = projectileTbl[1]
			if exploded == nil then
				return
			end

			local parts = workspace:GetPartBoundsInRadius(exploded.Position, exploded.Size.X / 2, findTrowelParams)

			local processedTrowels = {}
			for _, part in parts do
				local trowel = part.Parent
				if processedTrowels[trowel] then
					continue
				end

				processedTrowels[trowel] = true
				local head = LocalPlayer.Character:FindFirstChild("Head")

				local headPos = head.Position
				local trowelCF = trowel.PhysicsFolder.PlaceCFrame.Value
				local size, centerCF = getSize(trowel, headPos, trowelCF)

				local playerSide, oppositeSide, playerNormal = getSide(headPos, centerCF, size)

				-- Player isn't on either side of the trowel.
				if playerSide == nil then
					print("no side")
					continue
				end

				-- Explosion isn't on opposite side.
				if not isAbove(exploded.Position, centerCF.Position, -playerNormal) then
					print("explosion not on opposite side")
					continue
				end

				collisionPart.CFrame = centerCF
				collisionPart.Size = Vector3.new(size.X + MAX_DIST * 2, size.Y + 6, size.Z)
				findPlayerParams.FilterDescendantsInstances = { LocalPlayer.Character }

				local playerParts = workspace:GetPartsInPart(collisionPart, findPlayerParams)
				if playerParts[1] == nil then
					print("player not in line")
					continue
				end

				local toTrowel = (centerCF.Position - headPos).Unit
				local away = -Vector3.new(toTrowel.X, 0, toTrowel.Z).Unit
				local playerDist = ((playerSide - headPos) * Vector3.new(1, 0, 1)).Magnitude

				if playerDist > MAX_DIST then
					print("max dist")
					continue
				end

				local bombForce = Root.globals.dashingBombForce:Get()

				local explosionDist = (exploded.Position - oppositeSide).Magnitude
				local mag = (1 - math.clamp(playerDist / MAX_DIST - WIGGLE / MAX_DIST, 0, 1))
					* (1 - math.clamp(explosionDist / MAX_DIST_EXPLOSION - WIGGLE_EXPLOSION / MAX_DIST_EXPLOSION, 0, 1))
					* (bombForce * (size.X / TROWEL_LENGTH))

				head.AssemblyLinearVelocity += away * mag

				table.remove(trowels, table.find(trowels, trowel))
				findTrowelParams.FilterDescendantsInstances = { unpack(trowels) }
				break
			end
		end)
	end, function() end)
end

return trowelDashing
