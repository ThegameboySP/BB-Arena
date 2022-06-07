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

function General.weld(p0, p1)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = p0.CFrame:inverse() * p1.CFrame
	weld.Parent = p0
	return weld
end


return General