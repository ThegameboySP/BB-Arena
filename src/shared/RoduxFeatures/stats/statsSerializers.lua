local actions = require(script.Parent.statsActions)

return {
    {
        actionName = "stats_increment";
        serialize = function(action)
            local payload = action.payload
            return string.pack("dzd", payload.userId, payload.name, payload.amount)
        end;
        deserialize = function(serialized)
            return actions.incrementStatRaw(string.unpack("dzd", serialized))
        end;
    },
}