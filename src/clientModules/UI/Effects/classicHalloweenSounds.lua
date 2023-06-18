local function classicHalloweenSounds(soundParent)
	local sound = Instance.new("Sound")
	sound.Volume = 1
	sound.SoundId = "http://www.roblox.com/asset/?id=13061810"
	sound.Pitch = 0.3
	sound.Parent = soundParent
	sound:Play()

	local random = Random.new()
	local thread = task.spawn(function()
		while true do
			task.wait(random:NextInteger(7, 10))
			local m = random:NextInteger(1, 6)

			local clone = sound:Clone()
			clone.TimePosition = 0
			clone.Parent = soundParent
			if m == 1 then
				clone.SoundId = "http://www.roblox.com/asset/?id=13061810"
				clone.Pitch = 0.3
				clone:play()
			end

			if m == 2 then
				clone.SoundId = "http://www.roblox.com/asset/?id=13061809"
				clone.Pitch = 0.2
				clone:play()
			end

			if m == 3 then
				clone.SoundId = "http://www.roblox.com/asset/?id=13061810"
				clone.Pitch = 0.1
				clone:play()
			end

			if m == 4 then
				clone.SoundId = "http://www.roblox.com/asset/?id=13061802"
				clone.Pitch = 0.1
				clone:play()
			end

			if m == 5 then
				clone.SoundId = "http://www.roblox.com/asset/?id=13061809"
				clone.Pitch = 0.1
				clone:play()
			end

			if m == 6 then
				clone.SoundId = "http://www.roblox.com/asset/?id=12229501"
				clone.Pitch = 0.1
				clone:play()
			end
		end
	end)

	return sound, function()
		task.cancel(thread)
		sound.Parent = nil
	end
end

return classicHalloweenSounds
