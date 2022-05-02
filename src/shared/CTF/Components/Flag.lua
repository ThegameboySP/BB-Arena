return newComponent("Flag", {
    schema = {
        state = t.valueOf({"Carry", "Dropped", "OnStand"});
        player = t.optional(t.Instance);
        teamName = t.string;
    };
})