return function(context, name)
    local data = context:GetData()
    if data == nil then
        return
    end

    local GamemodeService = context:GetStore("Common").Root:GetService("GamemodeService")
	local _ok, msg = GamemodeService:SetGamemode(name, data.config)
	
	return msg
end