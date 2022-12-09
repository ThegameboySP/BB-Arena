return {
	Name = "resetStat",
	Aliases = { "rs" },
	Description = "Resets multiple players' stats.",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "players",
			Description = "Players to clear",
		},
	},
}
