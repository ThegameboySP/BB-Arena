return function(_, volume)
	volume = math.clamp(volume, 0, 2)

	local song = workspace:FindFirstChild("CmdrMusic")
	if song then
		local oldVolume = song.Volume
		song.Volume = volume
		return string.format("%.2f -> %.2f", oldVolume, volume)
	end

	return "No music is playing"
end
