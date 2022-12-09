local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(_, enabled)
	ReplicatedStorage:FindFirstChild("SendSpectateData").Value = enabled
end
