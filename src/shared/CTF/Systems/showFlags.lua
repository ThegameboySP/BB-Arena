local function showFlags(world, components, storage)
    for id, flagRecord in world:queryChanged(components.Flag) do
        if flagRecord.new and not storage[id] then
            storage[id] = TweenService:Create()
        elseif not flagRecord.new and storage[id] then
            storage[id]:Cancel()
        end
    end
end

return {
    system = showFlags;
    onDestruct = function(storage)
        for _, tween in pairs(storage) do
            tween:Cancel()
        end
    end;
}