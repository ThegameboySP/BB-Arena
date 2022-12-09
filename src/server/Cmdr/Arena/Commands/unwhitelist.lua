return {
	Name = "unwhitelist",
	Aliases = {},
	Description = "Removes UserId's as an exception for server locking.",
	Group = "Admin",
	Args = {
		{
			Type = "playerIds",
			Name = "players",
			Description = "Players to unwhitelist",
		},
	},
}
