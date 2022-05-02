return function (_, players, walkspeed)
    for _, player in pairs(players) do
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then continue end

        hum.WalkSpeed = walkspeed
    end
end