local RunService = game:GetService("RunService")

return function(_, players)
	for _, player in next, players do
		if player.Character == nil then
			continue
		end
		if player.Character.PrimaryPart == nil then
			continue
		end

		local CF = player.Character.PrimaryPart.CFrame
		local charCon
		charCon = player.CharacterAdded:Connect(function(character)
			if character.Parent == nil then
				character.AncestryChanged:Wait()
			end
			character.PrimaryPart.CFrame = CF
			local hbCon
			-- Spawning system naughtily repositions for a while, so we fight back.
			hbCon = RunService.Heartbeat:Connect(function()
				if character.PrimaryPart == nil then
					hbCon:Disconnect()
					charCon:Disconnect()
					return
				end
				if (character.PrimaryPart.Position - CF.p).Magnitude < 1 then
					hbCon:Disconnect()
					charCon:Disconnect()
				end
				character.PrimaryPart.CFrame = CF
			end)
		end)
		player:LoadCharacter()
	end
end
