return function(context)
	local GamemodeService = context:GetStore("Common").Root:GetService("GamemodeService")
	local ok = GamemodeService:StopGamemode()

	return ok and "Stopped gamemode." or "No gamemode is currently running."
end
