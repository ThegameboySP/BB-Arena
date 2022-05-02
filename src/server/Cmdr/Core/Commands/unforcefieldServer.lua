return function (_, players)
    for _, player in pairs(players) do
        local char = player.Character
        if not char then continue end

        local ff = char:FindFirstChildWhichIsA("ForceField")
        while ff do
            ff.Parent = nil
            ff = char:FindFirstChildWhichIsA("ForceField")
        end
    end
end