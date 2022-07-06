return {
	Name = "logs";
	Aliases = {"l"};
	Description = "Displays the command logs.";
	Group = "Any";
	Args = {
		{
			Type = "player $ string";
			Name = "player filter";
			Description = "The player to filter. Prefix with $ to use a player name (not display name).";
			Optional = true;
		}
	};
}