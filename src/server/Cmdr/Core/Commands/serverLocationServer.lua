local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

return function()
	if RunService:IsStudio() then
		return "You can't call serverLocation in Studio for privacy reasons"
	end

	local payload = HttpService:GetAsync("http://ip-api.com/json/")
	local info = HttpService:JSONDecode(payload)

	return string.format("%s, %s", info.region, info.country)
end
