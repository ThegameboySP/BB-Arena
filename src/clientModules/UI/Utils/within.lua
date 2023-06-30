local function within(instance, position)
	local pos = instance.AbsolutePosition
	local size = instance.AbsoluteSize

	return position.X >= pos.X
		and position.X <= (pos.X + size.X)
		and position.Y >= pos.Y
		and position.Y <= (pos.Y + size.Y)
end

return within
