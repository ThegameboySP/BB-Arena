local DEFAULT_DURATION = 2

for _, descendant in game:GetDescendants() do
	if descendant:IsA("SpawnLocation") then
		descendant.Duration = DEFAULT_DURATION
	end
end
