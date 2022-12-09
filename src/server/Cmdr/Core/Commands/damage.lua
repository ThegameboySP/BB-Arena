return {
	Name = "damage",
	Aliases = { "dmg" },
	Description = "Damages players the specified amount of health",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "Players",
			Description = "Players to damage",
		},
		{
			Type = "integer",
			Name = "Amount",
			Description = "Amount to damage by",
		},
	},
}
