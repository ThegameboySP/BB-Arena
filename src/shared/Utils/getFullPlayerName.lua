local function getFullPlayerName(player)
    local displayName = player.DisplayName
    local name = player.Name

    if displayName == name then
        return displayName
    end

    return displayName .. "@" .. name
end

return getFullPlayerName