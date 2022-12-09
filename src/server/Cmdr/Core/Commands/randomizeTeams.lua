return {
	Name = "randomizeTeams",
	Aliases = { "rt", "sortTeams" },
	Description = "Randomize a group players between a set of teams.",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "players",
			Description = "The players to sort into teams.",
		},
		{
			Type = "teams",
			Name = "teams",
			Description = "The teams that the players will be sorted into.",
		},
		{
			Type = "boolean",
			Name = "spawn",
			Description = "Whether to spawn the players or not.",
			Optional = true,
		},
	},
}
