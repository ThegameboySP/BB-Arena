return {
	Name = "give-forcefield",
	Aliases = { "ff" },
	Description = "Gives players a forcefield",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "Players",
			Description = "Players to give forcefield",
		},
	},
}
