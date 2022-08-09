return {
	Name = "objective";
	Aliases = {"o"};
	Description = "Displays the current objective at the bottom of the screen.";
	Group = "Admin";
	Args = {
		{
			Type = "string",
			Name = "message",
			Description = "Message that the objective will say"
		};
	};
}