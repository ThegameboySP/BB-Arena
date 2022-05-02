return {
	Name = "walkspeed";
	Aliases = {"ws"};
	Description = "Sets the walkspeed of players";
	Group = "Admin";
	Args = {
		{
			Type = "players";
			Name = "Players";
			Description = "Players whose walkspeed to set";
		},
		{
			Type = "number";
			Name = "Walkspeed";
			Description = "Walkspeed value to set";
		}
	};
}