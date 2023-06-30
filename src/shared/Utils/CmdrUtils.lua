local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local t = require(ReplicatedStorage.Packages.t)

local CmdrUtils = {}

local inf = math.huge

function CmdrUtils.wrapAutoSuggestions(type, generateAutoSuggestions)
	local clone = table.clone(type)
	clone.Autocomplete = function(...)
		local _, options = type.Autocomplete(...)
		return generateAutoSuggestions(), options
	end

	return clone
end

local function getValidateMsg(typeName, min, max)
	local capitalTypeName = typeName:sub(1, 1):upper() .. typeName:sub(2, -1)

	return if min == -inf and max ~= inf
		then ("%s must be within %d and below."):format(capitalTypeName, max)
		elseif min ~= -inf and max == inf then ("%s must be within %d and up."):format(capitalTypeName, min)
		else ("%s must be between %d and %d."):format(capitalTypeName, min, max)
end

function CmdrUtils.keyValueArgs(enumName, argIndex, getKeyValues, mapValue)
	mapValue = mapValue or function(...)
		return ...
	end

	local entries = {}

	return {
		function(context)
			entries = getKeyValues(context)

			local options = {}
			for key in entries do
				table.insert(options, key)
			end

			return {
				Type = context.Cmdr.Util.MakeEnumType(enumName, options),
				Name = "option name",
			}
		end,
		function(context)
			local arg1 = context:GetArgument(argIndex)
			if arg1:Validate() == false then
				return
			end

			local cmdrType, currentValue = mapValue(entries[arg1:GetValue()], arg1:GetValue(), context)
			local rawType = cmdrType
			if type(cmdrType) == "function" then
				rawType = cmdrType(context)
			end

			if type(rawType) == "table" then
				rawType = table.clone(rawType)
				rawType.Optional = false
				rawType.Default = nil

				if currentValue ~= nil then
					rawType.Description = (rawType.Description and (rawType.Description .. "\n\n") or "")
						.. "Current value: "
						.. tostring(currentValue)
				end
			end

			return rawType
		end,
	}
end

function CmdrUtils.constrainedInteger(min, max)
	local type = CmdrUtils.constrainedNumber(min, max)
	local validateMsg = getValidateMsg("integer", min, max)

	type.Validate = function(value)
		local isValid = value ~= nil and math.floor(value) == value and value >= min and value <= max

		return isValid, validateMsg
	end

	return type
end

function CmdrUtils.constrainedNumber(min, max)
	local validateMsg = getValidateMsg("number", min, max)

	return {
		DisplayName = "Integer " .. ("%s—%s"):format(
			min == -math.huge and "-inf" or tostring(min),
			max == math.huge and "inf" or tostring(max)
		),

		Transform = function(text)
			return tonumber(text)
		end,

		Validate = function(value)
			local isValid = value ~= nil and value >= min and value <= max

			return isValid, validateMsg
		end,

		Parse = function(value)
			return value
		end,
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
	Key = t.string,
	KeyType = t.table,
	KeyChecker = t.optional(t.callback),
	ValueType = t.table,
	ValueChecker = t.optional(t.callback),
}))

local IDef = t.strictInterface({
	Validate = t.optional(t.callback),
})

function CmdrUtils.fightingTeamTo(cmdrType, params)
	return function(commandContext)
		local schema = {}

		local resolvedCmdrType = cmdrType
		local Registry = commandContext.Cmdr.Registry
		if type(cmdrType) == "string" then
			resolvedCmdrType = Registry.Types[cmdrType]
		end

		for _, team in pairs(CollectionService:GetTagged("FightingTeam")) do
			table.insert(schema, {
				Key = team.Name,
				KeyType = Registry.Types.team,
				KeyChecker = t.literal(team),
				ValueType = resolvedCmdrType,
				ValueChecker = function()
					return true
				end,
			})
		end

		local wrappedCmdrType = {}
		wrappedCmdrType.Name = params.Name
		wrappedCmdrType.Description = params.Description

		wrappedCmdrType.Type = CmdrUtils.map(schema, {
			Validate = function(team, value)
				if not CollectionService:HasTag(team, "FightingTeam") then
					return false, string.format("%q is not a fighting team", team.Name)
				end

				if params.Validate then
					local ok, err = params.Validate(team, value)
					if not ok then
						return false, err
					end
				end

				return true
			end,
		})

		return wrappedCmdrType
	end
end

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

		checkers[entry.Key] = { Key = entry.KeyChecker, Value = entry.ValueChecker }
		cmdrTypes[entry.Key] = { Key = entry.KeyType, Value = entry.ValueType }
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
		ValidateOnce = def.Validate and function(key, value)
			local types = cmdrTypes[key]
			return def.Validate(getParsedValue(types.Key, key), getParsedValue(types.Value, value))
		end or nil,

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
				return { key .. "=" }
			end

			local suggestions = {}
			for index, str in ipairs(getAutocompleteValues(cmdrTypes[key].Value, value or "")) do
				suggestions[index] = key .. "=" .. str
			end

			return suggestions
		end,

		Parse = function(key, value)
			-- Cannot return a map since Cmdr expects an array from a listable type.
			-- Cannot return a single array since Cmdr removes order as an implementation detail.
			return {
				{
					type = "map",
					key = getParsedValue(cmdrTypes[key].Key, key),
					value = getParsedValue(cmdrTypes[key].Value, value),
				},
			}
		end,
	}
end

function CmdrUtils.transformType(value)
	if type(value) == "table" and value[1] then
		local valueType = value[1].type

		if valueType == "map" then
			local final = {}
			for _, entry in pairs(value) do
				final[entry.key] = entry.value
			end

			return final
		end
	end

	return value
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
	if cmdrType.Validate and not cmdrType.Validate(table.unpack(ret, 1, ret.n)) then
		return
	end
	return cmdrType.Parse(table.unpack(ret, 1, ret.n))
end

function getAutocompleteValues(cmdrType, value)
	if not cmdrType.Autocomplete then
		return {}
	end

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
			typeof(setOrContainer[1]) == "Instance"
			or typeof(setOrContainer[1]) == "EnumItem"
			or (typeof(setOrContainer[1]) == "table" and typeof(setOrContainer[1].Name) == "string")
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

--- Takes an array of instances and returns an array of those instances' names.
local function getNames(instances)
	local names = {}

	for i = 1, #instances do
		names[i] = instances[i].Name or tostring(instances[i])
	end

	return names
end

--- Makes an Enum type.
function CmdrUtils.enum(name, values)
	local findValue = makeFuzzyFinder(values)
	return {
		Validate = function(text)
			return findValue(text, true) ~= nil, ("Value %q is not a valid %s."):format(text, name)
		end,
		Autocomplete = function(text)
			local list = findValue(text)
			return type(list[1]) ~= "string" and getNames(list) or list
		end,
		Parse = function(text)
			return findValue(text, true)
		end,
	}
end

return CmdrUtils
