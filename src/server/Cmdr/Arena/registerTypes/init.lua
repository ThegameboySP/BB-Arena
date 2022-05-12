return function(registry, mapInfo)
    require(script.map)(registry, mapInfo)
    require(script.arenaPlayer)(registry)
    require(script.music)(registry)
end