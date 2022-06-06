return {
	Name = "kick";
	Aliases = {};
	Description = "Kicks players from this server.";
	Group = "Admin";
	Args = {
		{
			Type = "players",
			Name = "players",
			Description = "Players to kick."
		}
	};
}