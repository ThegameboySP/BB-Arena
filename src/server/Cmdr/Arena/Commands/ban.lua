return {
	Name = "ban";
	Aliases = {};
	Description = "Bans players from this local server.";
	Group = "Admin";
	Args = {
		{
			Type = "players # playerIds",
			Name = "players",
			Description = "Players to ban"
		}
	};
}