local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Packages.t)

local CmdrUtils = {}

function CmdrUtils.wrapAutoSuggestions(type, generateAutoSuggestions)
    local clone = table.clone(type)
    clone.Autocomplete = function(...)
        local _, options = type.Autocomplete(...)
        return generateAutoSuggestions(), options
    end

    return clone
end

function CmdrUtils.constrainedInteger(min, max)
	assert(min ~= -math.huge or max ~= math.huge, "Invalid parameters!")
	
	local validateMsg
	if min ~= -math.huge and max ~= math.huge then
		validateMsg = ("Integer must be between %d and %d."):format(min, max)
	else
		if min == -math.huge and max ~= math.huge then
			validateMsg = ("Integer must be below %d."):format(max + 1)
		elseif min ~= -math.huge and max == math.huge then
			validateMsg = ("Integer must be within %d and up."):format(min)
		end
	end
	
	return {
		DisplayName = "Integer " .. ("%s—%s"):format(
			min == -math.huge and "-inf" or tostring(min),
			max == math.huge and "inf" or tostring(max)
		);
		
		Transform = function(text)
			return tonumber(text)
		end;

		Validate = function(value)
			local isValid = value ~= nil
				and math.floor(value) == value
				and value >= min
				and value <= max
			
			return isValid, validateMsg
		end;

		Parse = function(value)
			return value
		end;
	}
end


function CmdrUtils.invalid(msg)
	msg = msg or "Invalid input. Go back and fix a previous argument."
	
	return {
		DisplayName = "Invalid",
		
		Validate = function()
			return false, msg
		end,
		
		Parse = function()
			return nil
		end,
	}
end

local ISchema = t.array(t.strictInterface({
	Key = t.string;
	KeyType = t.table;
	KeyChecker = t.optional(t.callback);
	ValueType = t.table;
	ValueChecker = t.optional(t.callback);
}))

local IDef = t.strictInterface({
	Validate = t.optional(t.callback);
})

function CmdrUtils.map(schema, def)
	assert(ISchema(schema))
	def = def or {}
	assert(IDef(def))
	
	local checkers = {}
	local cmdrTypes = {}
	local keys = {}
	
	for _, entry in ipairs(schema) do
		assert(not entry.KeyType.Listable, "Cannot make a keyword pair with a listable type!")
		assert(not entry.ValueType.Listable, "Cannot make a keyword pair with a listable type!")
		
		checkers[entry.Key] = {Key = entry.KeyChecker, Value = entry.ValueChecker}
		cmdrTypes[entry.Key] = {Key = entry.KeyType, Value = entry.ValueType}
		table.insert(keys, entry.Key)
	end

	local findKeys = makeFuzzyFinder(keys)
	return {
		DisplayName = "Map",
		Listable = true,

		Transform = function(text)
			local key, equals, value = text:match("(%w+)(=?)([^=,]*)")
			return key, value ~= "" and value or nil, equals ~= ""
		end,

		Validate = function(key, value)
			if key == nil then
				return false, "Map follows this format: key1=value1,key2=value2 etc"
			end

			local checkersPair = checkers[key]
			local types = cmdrTypes[key]
			if checkersPair == nil then
				return false, ("No key named %q!"):format(key)
			end
			
			do
				local ok, err = validateValue(types.Key, key)
				if not ok then
					return false, err
				end
			end

			key = getParsedValue(types.Key, key) or key
			do
				local ok, err = checkersPair.Key(key)
				if not ok then
					return false, err
				end
			end

			if value == nil then
				return false, "Map follows this format: key1=value1,key2=value2 etc"
			end

			do
				local ok, err = validateValue(types.Value, value)
				if not ok then
					return false, err
				end
			end

			value = getParsedValue(types.Value, value) or value
			do
				local ok, err = checkersPair.Value(value)
				if not ok then
					return false, err
				end
			end

			if def.Validate then
				return def.Validate(key, value)
			end
			
			return true
		end,
		
		-- Define this in case def's .Validate condition becomes cold before pressing enter.
		ValidateOnce = def.Validate
			and function(key, value)
				local types = cmdrTypes[key]
				return def.Validate(
					getParsedValue(types.Key, key),
					getParsedValue(types.Value, value)
				)
			end
			or nil,

		Autocomplete = function(key, value, hasEquals)
			if checkers[key] == nil then
				local suggestions = {}
				for _, _key in ipairs(findKeys(key or "")) do
					for _, suggestedKey in ipairs(getAutocompleteValues(cmdrTypes[_key].Key, _key)) do
						table.insert(suggestions, suggestedKey)
					end
				end
				
				return suggestions
			end
			
			if not hasEquals then
				return {key .. "="}
			end
			
			local suggestions = {}
			for index, str in ipairs(getAutocompleteValues(cmdrTypes[key].Value, value or "")) do
				suggestions[index] = key .. "=" .. str
			end
			
			return suggestions
		end,

		Parse = function(key, value)
			-- Cannot return a single table since Cmdr removes order.
			return {{
				getParsedValue(cmdrTypes[key].Key, key),
				getParsedValue(cmdrTypes[key].Value, value)
			}}
		end,
	}
end

function CmdrUtils.getKeywords(array)
	local keywords = {}
	for _, pair in ipairs(array) do
		keywords[pair[1]] = pair[2]
	end
	return keywords
end

function validateValue(cmdrType, value)
	if not cmdrType.Validate then
		return true
	end
	
	local ret = table.pack(cmdrType.Transform(value))
	local ok, err = cmdrType.Validate(table.unpack(ret, 1, ret.n))
	if not ok then
		return false, err
	end
	
	return true
end

function getParsedValue(cmdrType, value)
	local ret = table.pack(cmdrType.Transform(value))
	if cmdrType.Validate and not cmdrType.Validate(table.unpack(ret, 1, ret.n)) then return end
	return cmdrType.Parse(table.unpack(ret, 1, ret.n))
end

function getAutocompleteValues(cmdrType, value)
	local ret = table.pack(cmdrType.Transform(value))
	if cmdrType.Validate and not cmdrType.Validate(table.unpack(ret, 1, ret.n)) then
		return {}
	end
	
	return cmdrType.Autocomplete(table.unpack(ret, 1, ret.n))
end

-- Takes an array of instances and returns (array<names>, array<instances>)
local function transformInstanceSet(instances)
	local names = {}

	for i = 1, #instances do
		names[i] = instances[i].Name
	end

	return names, instances
end

--- Returns a function that is a fuzzy finder for the specified set or container.
-- Can pass an array of strings, array of instances, array of EnumItems,
-- array of dictionaries with a Name key or an instance (in which case its children will be used)
-- Exact matches will be inserted in the front of the resulting array
function makeFuzzyFinder(setOrContainer)
	local names
	local instances = {}

	if typeof(setOrContainer) == "Enum" then
		setOrContainer = setOrContainer:GetEnumItems()
	end

	if typeof(setOrContainer) == "Instance" then
		names, instances = transformInstanceSet(setOrContainer:GetChildren())
	elseif typeof(setOrContainer) == "table" then
		if
			typeof(setOrContainer[1]) == "Instance" or typeof(setOrContainer[1]) == "EnumItem" or
				(typeof(setOrContainer[1]) == "table" and typeof(setOrContainer[1].Name) == "string")
		then
			names, instances = transformInstanceSet(setOrContainer)
		elseif type(setOrContainer[1]) == "string" then
			names = setOrContainer
		elseif setOrContainer[1] ~= nil then
			error("MakeFuzzyFinder only accepts tables of instances or strings.")
		else
			names = {}
		end
	else
		error("MakeFuzzyFinder only accepts a table, Enum, or Instance.")
	end

	-- Searches the set (checking exact matches first)
	return function(text, returnFirst)
		local results = {}

		for i, name in pairs(names) do
			local value = instances and instances[i] or name

			-- Continue on checking for non-exact matches...
			-- Still need to loop through everything, even on returnFirst, because possibility of an exact match.
			if name:lower() == text:lower() then
				if returnFirst then
					return value
				else
					table.insert(results, 1, value)
				end
			elseif name:lower():sub(1, #text) == text:lower() then
				results[#results + 1] = value
			end
		end

		if returnFirst then
			return results[1]
		end

		return results
	end
end

return CmdrUtils