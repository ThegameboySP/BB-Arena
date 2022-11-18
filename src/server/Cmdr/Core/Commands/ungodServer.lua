return function(_, players)
    for _, player in players do
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")

        if humanoid then
            humanoid:SetAttribute("IsGodded", nil)
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
    end
end