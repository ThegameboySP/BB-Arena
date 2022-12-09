return function(_, players, health)
	for _, player in pairs(players) do
		local char = player.Character
		if not char then
			continue
		end
		local hum = char:FindFirstChild("Humanoid")
		if not hum then
			continue
		end

		hum.Health = health
	end
end
