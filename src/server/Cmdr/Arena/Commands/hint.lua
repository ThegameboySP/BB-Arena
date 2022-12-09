return {
	Name = "Hint",
	Aliases = { "h" },
	Description = "Creates an unobtrusive message at the top of the screen.",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "message",
			Description = "Message that the hint will say",
		},
	},
}
