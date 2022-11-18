return {
    Name = "setTimer";
    Aliases = {"timer"};
    Group = "Admin";
    Description = "Sets the global game timer.";
    Args = {
        {
            Type = "duration";
            Name = "duration";
            Description = "The amount of time to set the timer to";
        },
    };
}