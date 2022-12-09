local function blendAlpha(alphaValues)
	local alpha = 0

	for _, value in alphaValues do
		alpha = alpha + (1 - alpha) * value
	end

	return alpha
end

return blendAlpha
