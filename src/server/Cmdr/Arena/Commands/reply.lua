return {
	Name = "reply";
	Aliases = {};
	Description = "Replies your text back to you.";
	Group = "Utility";
	Args = {
		{
			Type = "string";
			Name = "Text";
			Description = "The text."
		},
		{
			Type = "color3",
			Name = "Color";
			Description = "The color of the reply.";
			Optional = true;
		}
	};

	Run = function(context, text, color)
		context:Reply(text, color or Color3.new(1, 1, 1))
		return ""
	end
}