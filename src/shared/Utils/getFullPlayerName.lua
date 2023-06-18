local function getFullPlayerName(object, second)
	local displayName
	local name

	if typeof(object) == "Instance" then
		displayName = object.DisplayName
		name = object.Name
	-- UserInfoResponse
	elseif type(object) == "table" then
		displayName = object.DisplayName
		name = object.Username
	elseif type(object) == "string" and type(second) == "string" then
		displayName = object
		name = second
	end

	if displayName == name then
		return displayName
	end

	return displayName .. "@" .. name
end

return getFullPlayerName
