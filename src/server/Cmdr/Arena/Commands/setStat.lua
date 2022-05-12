return {
	Name = "setStat";
	Aliases = {"set"};
	Description = "Sets multiple players' stats.";
	Group = "Admin";
	Args = {
        {
            Type = "players";
            Name = "players";
            Description = "Players to set";  
        },
		{
			Type = "string";
			Name = "stat name";
			Description = "The name of the stat";
		},
        {
            Type = "number",
            Name = "stat value",
            Description = "The value of the stat";
        }
	};
}