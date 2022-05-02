return {
	Name = "respawn";
	Aliases = {"spawn"};
	Description = "Respawns players";
	Group = "Admin";
	Args = {
		{
			Type = "players";
			Name = "Players";
			Description = "Names of the players to respawn";
		},
	};
}