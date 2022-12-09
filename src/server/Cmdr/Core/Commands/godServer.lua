return function(_, players)
	for _, player in players do
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")

		if humanoid then
			humanoid:SetAttribute("IsGodded", true)
			humanoid.MaxHealth = math.huge
			humanoid.Health = math.huge
		end
	end
end
