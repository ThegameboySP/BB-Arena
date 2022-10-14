return function(registry, mapInfo)
    for _, child in script:GetChildren() do
        require(child)(registry, mapInfo)
    end
end