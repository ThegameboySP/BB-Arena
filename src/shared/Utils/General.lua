local Players = game:GetService("Players")

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

function General.getCharacter(instance)
	local node = instance

	while node do
		local hum = node:FindFirstChild("Humanoid")
		if hum then
			return node, hum
		end

		node = node.Parent
	end

	return nil
end

function General.getCharacterFromHitbox(instance)
	local parent = instance.Parent
	if parent then
		local hum = parent:FindFirstChild("Humanoid")
		if hum then
			return parent, hum
		end
	end

	return nil
end

function General.getPlayerFromHitbox(instance)
	local character = General.getCharacterFromHitbox(instance)
	if character then
		return Players:GetPlayerFromCharacter(character), character
	end
end

function General.getPlayer(instance)
	local character = General.getPlayer(instance)
	if character then
		return Players:GetPlayerFromCharacter(character), character
	end
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
