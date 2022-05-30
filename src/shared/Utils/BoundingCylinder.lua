local BoundingCylinder = {}

-- "pos" is bottom center of the cylinder.
function BoundingCylinder.isPointIntersecting(pos, radius, height, point)
	local delta = point - pos
	
	return
        (Vector3.new(delta.X, 0, delta.Z).Magnitude) <= radius
		and (point.Y >= pos.Y)
        and (point.Y <= (pos.Y + height))
end

return BoundingCylinder