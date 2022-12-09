local CollectionService = game:GetService("CollectionService")

return function(signals)
	local participantDied = signals.participantDied

	signals.playerDied:Connect(function(player, info)
		local team = player.Team
		if team and CollectionService:HasTag(team, "ParticipatingTeam") then
			participantDied:Fire(player, info)
		end
	end)
end
