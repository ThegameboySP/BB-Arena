local ThumbnailAnimator = {}
ThumbnailAnimator.__index = ThumbnailAnimator

function ThumbnailAnimator.new(thumbnail)
	return setmetatable({
		thumbnail = thumbnail,
		started = os.clock(),
		scrollingDirection = thumbnail.scrollingDirection or "Y",
		scrollingBehavior = thumbnail.scrollingBehavior or "Sine",
		scrollingTime = thumbnail.scrollingTime or 14,
	}, ThumbnailAnimator)
end

function ThumbnailAnimator:Update()
	local extra = 0
	local elapsedTime = math.clamp(os.clock() - self.started, 0, self.scrollingTime)

	if self.scrollingBehavior == "Sine" then
		extra = math.sin(elapsedTime * (math.pi * 2) / 8) * 8
	elseif self.scrollingBehavior == "Linear" then
		local speed = 40 / self.scrollingTime
		extra = (elapsedTime * -speed) + 20
	end

	if self.scrollingDirection == "X" then
		self.thumbnail.setPosition(UDim2.new(0.5, extra, 0.5, 0))
	elseif self.scrollingDirection == "Y" then
		self.thumbnail.setPosition(UDim2.new(0.5, 0, 0.5, extra))
	end

	return (elapsedTime + 0.1) >= self.scrollingTime
end

return ThumbnailAnimator
