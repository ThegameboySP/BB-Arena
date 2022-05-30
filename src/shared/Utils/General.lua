local General = {}

function General.isValidCharacter(char)
    if typeof(char) ~= "Instance" then
        return false
    end

    local hum = char:FindFirstChild("Humanoid")
    if hum == nil then
        return false
    end

    return hum.Health > 0
end

return General