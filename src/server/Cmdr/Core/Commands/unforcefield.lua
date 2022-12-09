return {
	Name = "unforcefield",
	Aliases = { "unff" },
	Description = "Takes away players forcefields",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "Players",
			Description = "Players whose forcefield to take away",
		},
	},
}
