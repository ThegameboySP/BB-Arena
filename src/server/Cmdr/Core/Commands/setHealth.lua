return {
	Name = "sethealth";
	Aliases = {"health"};
	Description = "Sets players the specified amount of health";
	Group = "Admin";
	Args = {
		{
			Type = "players";
			Name = "Players";
			Description = "Players to set health";
		},
		{
			Type = "integer";
			Name = "Amount";
			Description = "Amount of health";
		},
	};
}