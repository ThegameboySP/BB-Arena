return {
	Name = "setVolume",
	Aliases = { "volume" },
	Description = "Sets the volume for the current song.",
	Group = "Admin",
	Args = {
		{
			Type = "number",
			Name = "volume",
			Description = "The volume to set the music to",
		},
	},
}
