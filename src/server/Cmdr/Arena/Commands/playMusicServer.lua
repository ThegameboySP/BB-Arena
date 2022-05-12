return function (_, soundIdOrSound, volume, looped)
	if workspace:FindFirstChild("CmdrMusic") then
		workspace.CmdrMusic:Destroy()
	end
	
	if typeof(soundIdOrSound) == "number" then
		local music = Instance.new("Sound")
		music.Name = "CmdrMusic"
		music.SoundId = "rbxassetid://" .. soundIdOrSound
		music.Looped = looped

		music.Volume = math.clamp(0.5 + (volume or 0), 0, 2)
		music.Parent = workspace
		music:Play()

        return string.format("Playing #%s", soundIdOrSound)
	elseif typeof(soundIdOrSound) == "Instance" then
		local music = soundIdOrSound:Clone()
		music.Name = "CmdrMusic"
		music.Looped = looped

		music.Volume = math.clamp(music.Volume + (volume or 0), 0, 2)
		music.Parent = workspace
		music:Play()

        return string.format("Playing %q", soundIdOrSound.Name)
	end
end