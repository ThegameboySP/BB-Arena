return function(_, players)
	for _, player in pairs(players) do
		task.spawn(player.LoadCharacter, player)
	end
end
