return function (_, players)
    for _, player in pairs(players) do
        local char = player.Character
        if not char then continue end
        if char:FindFirstChildWhichIsA("ForceField") then continue end

        local ff = Instance.new("ForceField")
        ff.Parent = char
    end
end