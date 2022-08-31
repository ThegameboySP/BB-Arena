local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local function get(state, ...)
    local current = state

    for i = 1, select("#", ...) do
        local key = select(i, ...)
        current = current[key]

        if current == nil then
            return nil
        end
    end

    return current
end

local function changed(new, old, ...)
    if new == nil or old == nil then
        return new ~= old
    end

    return get(new, ...) ~= get(old, ...)
end

local userId = Players.LocalPlayer.UserId

local function respectSettings(root)
    local function onChanged(new, old)
        assert(new, "New Rodux state was somehow nil")
        
        if not changed(new, old, "users", "userSettings", userId) then
            return
        end

        local settings = get(root.Store:getState(), "users", "userSettings", userId)
        SoundService.Music.Volume = 2 * settings.musicVolume
        SoundService.Map.Volume = 2 * settings.mapVolume
    end

    root.Store.changed:connect(onChanged)
    onChanged(root.Store:getState(), nil)
end

return respectSettings