local function classicHalloweenSounds(soundParent)
	local soundGroup = Instance.new("SoundGroup")
	soundGroup.Volume = 0.5
	soundGroup.Parent = soundParent

	local lastHigh
	local function setHigh(sound)
		if lastHigh then
			lastHigh.Parent = nil
		end

		lastHigh = sound
	end

	local random = Random.new()
	local thread = task.spawn(function()
		local m = random:NextInteger(1, 6)

		local lastSound
		while true do
			if random:NextInteger(1, 10) == 1 then
				if lastSound then
					lastSound.Parent = nil
				end

				task.wait(5)
			end

			local sound = Instance.new("Sound")
			lastSound = sound
			sound.SoundGroup = soundGroup
			sound.Volume = 1
			sound.Parent = soundGroup
			sound.Ended:Connect(function()
				sound.Parent = nil
			end)

			if m == 1 then
				sound.SoundId = "http://www.roblox.com/asset/?id=13061810"
				sound.Pitch = 0.3
				sound:Play()
			end

			if m == 2 then
				setHigh(sound)
				sound.SoundId = "http://www.roblox.com/asset/?id=13061809"
				sound.Pitch = 0.2
				sound:Play()
			end

			if m == 3 then
				setHigh(sound)
				sound.SoundId = "http://www.roblox.com/asset/?id=13061810"
				sound.Pitch = 0.1
				sound:Play()
			end

			if m == 4 then
				setHigh(sound)
				sound.SoundId = "http://www.roblox.com/asset/?id=13061802"
				sound.Pitch = 0.1
				sound:Play()
			end

			if m == 5 then
				setHigh(sound)
				sound.SoundId = "http://www.roblox.com/asset/?id=13061809"
				sound.Pitch = 0.1
				sound:Play()
			end

			if m == 6 then
				sound.SoundId = "http://www.roblox.com/asset/?id=12229501"
				sound.Pitch = 0.1
				sound:Play()
			end

			task.wait(random:NextInteger(7, 10))
			m = random:NextInteger(1, 6)
		end
	end)

	return soundGroup, function()
		task.cancel(thread)
		soundGroup.Parent = nil
	end
end

return classicHalloweenSounds
