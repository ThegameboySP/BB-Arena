return {
	Name = "unlockCommands";
	Aliases = {"unlock"};
	Description = "Unlocks commands if it was locked by an admin greater than or equal to you.";
	Group = "Admin";
	Args = {
		{
			Type = "commands";
			Name = "commands";
			Description = "The commands to unlock.";
		}
	};
}