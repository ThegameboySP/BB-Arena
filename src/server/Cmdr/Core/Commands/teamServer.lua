return function(_, players, team)
	for _, player in pairs(players) do
		player.Team = team
	end
end
