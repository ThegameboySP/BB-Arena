return {
	Name = "playMusic";
	Aliases = {"music", "play"};
	Description = "Plays music by the given sound Id.";
	Group = "Admin";
	Args = {
		{
			Type = "integer $ music",
			Name = "sound Id",
			Description = "The music. Use $ for preloaded songs"
		},
		{
			Type = "number",
			Name = "additional volume",
			Description = "Additional volume to add to the music",
			Optional = true
		},
		{
			Type = "boolean",
			Name = "looped",
			Description = "Whether to loop the music or not";
			Optional = true;
		}
	};
}