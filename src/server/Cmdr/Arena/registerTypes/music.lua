local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrMusic = ReplicatedStorage.Assets.Music

return function(registry)
	local Util = registry.Cmdr.Util
	local findMusic = Util.MakeFuzzyFinder(CmdrMusic)
	
	registry:RegisterType("music", {
		DisplayName = "Music";
		
		Transform = function(text)
			return text
		end,
		
		Validate = function(musicName)
			return findMusic(musicName, true) or ("Value %q is not a valid music name."):format(musicName)
		end,
		
		Autocomplete = function(text)
            local names = {}
            for _, instance in pairs(findMusic(text)) do
                table.insert(names, instance.Name)
            end
            
            return names
		end,
		
		Parse = function(text)
			return findMusic(text, true)
		end
	})
end