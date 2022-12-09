return {
	Name = "unban",
	Aliases = {},
	Description = "Unbans UserIds.",
	Group = "Admin",
	Args = {
		{
			Type = "playerIds",
			Name = "players",
			Description = "Players to unban",
		},
	},
}
