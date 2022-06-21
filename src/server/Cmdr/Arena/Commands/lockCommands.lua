return {
	Name = "lockCommands";
	Aliases = {"lock"};
	Description = "Locks commands from every admin beneath you.";
	Group = "Admin";
	Args = {
		{
			Type = "commands";
			Name = "commands";
			Description = "The commands to lock.";
		}
	};
}