local BoundingBox = {}

local CORNER_MULTIPLIERS = {
	Vector3.new(-1, -1, 1),
	Vector3.new(1, -1, 1),
	Vector3.new(-1, -1, -1),
	Vector3.new(1, -1, -1),

	Vector3.new(-1, 1, 1),
	Vector3.new(1, 1, 1),
	Vector3.new(-1, 1, -1),
	Vector3.new(1, 1, -1),
}

function BoundingBox.isAbove(point, planePoint, normal)
	local relative = point - planePoint
	return relative:Dot(normal) > 0 -- if point is above plane
end

function BoundingBox.getPoints(CF, size)
	local points = table.create(8)
	local hSize = size / 2

	for index, corner in ipairs(CORNER_MULTIPLIERS) do
		points[index] = CF:PointToWorldSpace(corner * hSize)
	end

	return points
end

function BoundingBox.getMinMax(parts)
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

	for _, part in next, parts do
		for _, point in next, BoundingBox.getPoints(part.CFrame, part.Size) do
			local x, y, z = point.X, point.Y, point.Z

			minX, maxX = math.min(x, minX), math.max(x, maxX)
			minY, maxY = math.min(y, minY), math.max(y, maxY)
			minZ, maxZ = math.min(z, minZ), math.max(z, maxZ)
		end
	end

	return minX, minY, minZ, maxX, maxY, maxZ
end

function BoundingBox.getAABB(parts)
	local minX, minY, minZ, maxX, maxY, maxZ = BoundingBox.getMinMax(parts)
	local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
	local center = Vector3.new(minX, minY, minZ) + (size / 2)

	return center, size, minX, minY, minZ, maxX, maxY, maxZ
end

function BoundingBox.isAABBIntersecting(
	aMinX,
	aMinY,
	aMinZ,
	aMaxX,
	aMaxY,
	aMaxZ,
	bMinX,
	bMinY,
	bMinZ,
	bMaxX,
	bMaxY,
	bMaxZ
)
	return (aMinX <= bMaxX and aMaxX >= bMinX)
		and (aMinY <= bMaxY and aMaxY >= bMinY)
		and (aMinZ <= bMaxZ and aMaxZ >= bMinZ)
end

function BoundingBox.isPointIntersecting(x, y, z, minX, minY, minZ, maxX, maxY, maxZ)
	return (x >= minX and x <= maxX) and (y >= minY and y <= maxY) and (z >= minZ and z <= maxZ)
end

return BoundingBox
