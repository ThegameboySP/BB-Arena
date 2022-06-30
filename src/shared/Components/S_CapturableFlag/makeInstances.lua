return function(instance, radiusSize, noBottomCollision, bottomCollisionHeight)
	local pole = instance.Pole
	local poleBottomPos = pole.Position - Vector3.new(0, pole.Size.X / 2, 0)

	local radius = Instance.new("Part")
	radius.Name = "Radius"
	radius.Shape = Enum.PartType.Cylinder
	radius.Anchored = true
	radius.CanCollide = false
	radius.CanQuery = false
	radius.CastShadow = false
	radius.BrickColor = BrickColor.Blue()
	radius.TopSurface = Enum.SurfaceType.Smooth
	radius.BottomSurface = Enum.SurfaceType.Smooth
	
	if noBottomCollision then
		radius.Size = Vector3.new(0.001, radiusSize * 2, radiusSize * 2)
	else
		radius.Size = Vector3.new(bottomCollisionHeight, radiusSize * 2, radiusSize * 2)
	end
	radius.CFrame = CFrame.new(poleBottomPos - Vector3.new(0, radius.Size.X / 2 - 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2)

	return
		radius,
		noBottomCollision and poleBottomPos or poleBottomPos - Vector3.new(0, bottomCollisionHeight, 0),
		noBottomCollision and 40 or 40 + bottomCollisionHeight
end