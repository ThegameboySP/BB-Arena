return {
    Name = "whitelist";
    Aliases = {};
    Description = "Makes UserId's an exception for server locking.";
    Group = "Admin";
    Args = {
        {
            Type = "playerIds",
            Name = "players";
            Description = "Players to whitelist";
        }
    }
}