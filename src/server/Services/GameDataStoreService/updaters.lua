return {
	{
		onVersion = "0.0.1",
		step = function(data)
			data.stats = {}
			return data
		end,
	},
	{
		onVersion = "0.0.2",
		step = function(data)
			data.settings.practiceWeaponDisplay = nil
			return data
		end,
	},
}
