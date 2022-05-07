local CollectionService = game:GetService("CollectionService")

local Effects = {}

local RET_TRUE = function()
    return true
end

function Effects.pipe(effects)
	local len = #effects
	local cached = table.create(len)
	
	local function pipe(effect, nextPipe)
		return function(item, rootAdd, rootRemove, context)
			local subItemToPipeDestructor = {}

			local function add(subItem, subContext)
				if subItemToPipeDestructor[subItem] then return end

				local resolvedContext
				if context and subContext then
					resolvedContext = table.clone(context)
					
					for key, value in pairs(subContext) do
						resolvedContext[key] = value
					end
				else
					resolvedContext = subContext or context
				end

				if nextPipe then
					subItemToPipeDestructor[subItem] = 
						nextPipe(subItem, rootAdd, rootRemove, resolvedContext)
						or function() end
				else
					subItemToPipeDestructor[subItem] = function() end
					rootAdd(subItem, resolvedContext)
				end
			end

			local function remove(subItem)
				local destructor = subItemToPipeDestructor[subItem]
				if destructor == nil then return end

				destructor()
				subItemToPipeDestructor[subItem] = nil

				if nextPipe == nil then
					rootRemove(subItem)
				end
			end

			local destructor = effect(item, add, remove, context)
			return function()
				if destructor then
					destructor()
				end
				
				for subItem, subDestructor in pairs(subItemToPipeDestructor) do
					subDestructor()
					subItemToPipeDestructor[subItem] = nil
					
					if nextPipe == nil then
						rootRemove(subItem)
					end
				end
			end
		end
	end
	
	for i=len, 1, -1 do
		cached[i] = pipe(effects[i], cached[i + 1])
	end
	
	return function(item, rootAdd, rootRemove, context)
		return Effects.bufferAll(cached[1])(item, rootAdd, rootRemove, context)
	end
end

-- Transforms all item streams into one stream, adding and removing only when
-- all streams agree. To be used at very top of effect.
-- WARNING: The returned function is stateful and cannot be reused.
	function Effects.bufferAll(func)
		local itemsCount = {}
	
		return function(item, add, remove, context)
			local added = {}
	
			return func(item, function(subItem, ...)
				if added[subItem] then return end
				added[subItem] = true
	
				itemsCount[subItem] = itemsCount[subItem] or 0
				itemsCount[subItem] += 1
				add(subItem, ...)
			end, function(subItem, ...)
				if not added[subItem] then return end
				if itemsCount[subItem] == nil then return end
				added[subItem] = nil
	
				itemsCount[subItem] -= 1
				if itemsCount[subItem] == 0 then
					itemsCount[subItem] = nil
					remove(subItem, ...)
				end
			end, context)
		end
	end

-- Guards against redundant add/remove calls.
function Effects.buffer(func)
	return function(item, add, remove, context)
		local added = {}

		return func(item, function(subItem, ...)
			if added[subItem] then return end

			added[subItem] = true
			add(subItem, ...)
		end, function(subItem)
			if not added[subItem] then return end

			added[subItem] = nil
			remove(subItem)
		end, context)
	end
end

-- Combines multiple functions into one.
function Effects.combine(funcs)
	return function(item, add, remove, context)
		local itemsCount = {}
		local destructors = {}

		for _, func in pairs(funcs) do
			local added = {}

			table.insert(destructors, func(item, function(subItem, ...)
				if added[subItem] then return end
				added[subItem] = true

				itemsCount[subItem] = itemsCount[subItem] or 0
				itemsCount[subItem] += 1

				add(subItem, ...)
			end, function(subItem, ...)
				if added[subItem] == nil then return end
				if itemsCount[subItem] == nil then return end

				itemsCount[subItem] -= 1
				if itemsCount[subItem] == 0 then
					itemsCount[subItem] = nil
					remove(subItem, ...)
				end
			end, context))
		end

		return function()
			for _, destructor in pairs(destructors) do
				destructor()
			end
		end
	end
end

function Effects.conditionOrError(func)
	return function(item, add, remove, context)
		return func(item, function(subItem, ...)
			if subItem ~= item then
				error(("Added an item other than the input: source = %s (%s); output = %s (%s)")
					:format(item, tostring(item), subItem, tostring(subItem)))
			end

			add(subItem, ...)
		end, function(subItem)
			if subItem ~= item then
				error(("Removed an item other than the input: source = %s (%s); output = %s (%s)")
					:format(item, tostring(item), subItem, tostring(subItem)))
			end

			remove(subItem)
		end, context)
	end
end

function Effects.filterItems(filter, updateFilter)
	return function(item, add, remove, context)
		if filter(item, context) then
			add(item)
		end

		local con
		if updateFilter then
			con = updateFilter:Connect(function()
				if filter(item) then
					add(item, context)
				else
					remove(item)
				end
			end)
		end
		
		return con and function()
			con:Disconnect()
		end
	end
end

function Effects.map(map)
	return function(item, add, _, context)
		add(map(item, context))
	end
end

function Effects.log(name)
	local prefix = string.format("[%s]:", name)

	return function(item, add, _, context)
		print(prefix, "added:", item, context)
		add(item)
		return function()
			print(prefix, "removed:", item, context)
		end
	end
end

local function makeConditions(shouldPass, shouldFail)
	return function(conditions)
		local len = #conditions
		local wrappedConditions = table.create(len)
		for _, condition in pairs(conditions) do
			table.insert(wrappedConditions, Effects.conditionOrError(condition))
		end

		return function(item, add, remove, context)
			local destructors = {}
			local okConditions = {}
			local passed = 0

			for _, condition in pairs(wrappedConditions) do
				table.insert(destructors, condition(item, function()
					if okConditions[condition] then return end
					okConditions[condition] = true
					passed += 1

					if shouldPass(passed, len) then
						add(item)
					end
				end, function()
					if okConditions[condition] == nil then return end
					okConditions[condition] = nil
					passed -= 1

					if shouldFail(passed, len) then
						remove(item)
					end
				end, context))
			end

			return function()
				for _, destructor in pairs(destructors) do
					destructor()
				end
			end
		end
	end
end

Effects.testAll = makeConditions(function(passed, len)
	return passed == len
end, RET_TRUE)

Effects.testAny = makeConditions(RET_TRUE, function(passed)
	return passed == 0
end)

function Effects.testSome(amount, conditions)
	return makeConditions(function(passed)
		return passed >= amount
	end, function(passed)
		return passed < amount
	end)(conditions)
end

function Effects.isA(class)
	return function(instance, add)
		if instance:IsA(class) then
			add(instance)
		end
	end
end

-- Passes if all children pass the condition.
function Effects.testChildren(condition)
	local buffered = Effects.buffer(Effects.conditionOrError(condition))

	return function(instance, add, remove, context)
		local passed = 0
		local childrenCount = 0
		local passedByChildren = {}
		local destructorByChildren = {}
		
		local function update()
			if passed >= childrenCount then
				add(instance)
			else
				remove(instance)
			end
		end

		local function onChildAdded(child)
			childrenCount += 1

			destructorByChildren[child] = buffered(child, function()
				passedByChildren[child] = true
				passed += 1
				update()
			end, function()
				passedByChildren[child] = nil
				passed -= 1
				update()
			end, context)
		end

		local con1 = instance.ChildAdded:Connect(onChildAdded)
		for _, child in pairs(instance:GetChildren()) do
			onChildAdded(child)
		end

		local con2 = instance.ChildRemoved:Connect(function(child)
			childrenCount -= 1

			local destructor = destructorByChildren[child]
			if destructor then
				destructor()
			end

			if passedByChildren[child] then
				passed -= 1
			end

			destructorByChildren[child] = nil
			passedByChildren[child] = nil

			update()
		end)

		return function()
			con1:Disconnect()
			con2:Disconnect()
		end
	end
end

local function onPropertyChanged(instance, name, callback)
	local destructor
	local function onChanged()
		if destructor then
			destructor()
		end
		destructor = callback()
	end
	local con = instance:GetPropertyChangedSignal(name):Connect(onChanged)
	onChanged()

	return function()
		con:Disconnect()
		if destructor then
			destructor()
		end
	end
end

-- Makes 1 condition out of an AND of children conditions. Implied .Name condition is included.
-- Does not need to buffer, as .testChildren does this.
function Effects.testChildrenNamed(children)
	return Effects.testChildren(function(child, add, remove, context)
		return onPropertyChanged(child, "Name", function()
			local condition = children[child.Name]
			if condition == nil then return end

			local function onRemove()
				remove(child)
			end

			local destruct = condition(child, function()
				add(child)
			end, onRemove, context)

			return function()
				if destruct then
					destruct()
				end
				onRemove()
			end
		end)
	end)
end

function Effects.childrenFilter(filter, connectChanged)
	return function(instance, add, remove)
		local destructors = {}
		local function onChildAdded(child)
			local function update()
				if filter(child) then
					add(child)
				else
					remove(child)
				end
			end

			if connectChanged then
				destructors[child] = connectChanged(child, update)
			end
			update()
		end

		local con1 = instance.ChildAdded:Connect(onChildAdded)
		local con2 = instance.ChildRemoved:Connect(function(child)
			remove(child)
			local destructor = destructors[child]
			if destructor then
				destructor()
			end
		end)

		for _, child in pairs(instance:GetChildren()) do
			onChildAdded(child)
		end

		return function()
			con1:Disconnect()
			con2:Disconnect()
			for _, destructor in pairs(destructors) do
				destructor()
			end
		end
	end
end

function Effects.tag(tagName)
	return function(instance, add)
		CollectionService:AddTag(instance, tagName)
		add(instance)

		return function()
			CollectionService:RemoveTag(instance, tagName)
		end
	end
end

function Effects.childrenNamed(name)
	return Effects.childrenFilter(function(instance)
		return instance.Name == name
	end, function(instance, callback)
		local con = instance:GetPropertyChangedSignal("Name"):Connect(callback)
		return function()
			con:Disconnect()
		end
	end)
end
Effects.children = Effects.childrenFilter(RET_TRUE)

local function makeMetaCondition(verify, getSignal)
	return function(conditions)
		return function(instance, add, remove)
			local unsatisfiedProperties = {}
			local destructors = {}

			for name, value in pairs(conditions) do
				local function onChanged()
					if verify(instance, name, value) then
						unsatisfiedProperties[name] = nil
						if not next(unsatisfiedProperties) then
							add(instance)
						end
					else
						unsatisfiedProperties[name] = true
						remove(instance)
					end
				end

				table.insert(destructors, getSignal(instance, name, onChanged))
				onChanged()
			end

			return function()
				for _, destructor in pairs(destructors) do
					destructor()
				end
			end
		end
	end
end

Effects.hasProperties = makeMetaCondition(function(i, name, value)
	return i[name] == value
end, function(i, name, callback)
	local con = i:GetPropertyChangedSignal(name):Connect(callback)
	return function()
		con:Disconnect()
	end
end)

Effects.hasAttributes = makeMetaCondition(function(i, name, value)
	return i:GetAttribute(name) == value
end, function(i, name, callback)
	local con = i:GetAttributeChangedSignal(name):Connect(callback)
	return function()
		con:Disconnect()
	end
end)

function Effects.character(player, add, remove)
	local cons = {}

	local function addCharacterIfValid(character)
		if character:FindFirstChild("Humanoid") == nil then
			local id = #cons + 1

			cons[id] = character.ChildAdded:Connect(function(child)
				if not child:IsA("Humanoid") then return end

				cons[id]:Disconnect()
				cons[id] = nil
				add(character)
			end)
		else
			add(character)
		end
	end

	local function onCharacterAdded(character)
		-- https://devforum.roblox.com/t/avatar-loading-event-ordering-improvements/269607
		if character.Parent then
			addCharacterIfValid(character)
		else
			local id = #cons + 1
			
			cons[id] = character.AncestryChanged:Connect(function()
				cons[id]:Disconnect()
				cons[id] = nil

				addCharacterIfValid(character)
			end)
		end
	end

	table.insert(cons, player.CharacterAdded:Connect(onCharacterAdded))
	table.insert(cons, player.CharacterRemoving:Connect(remove))

	local character = player.Character
	if character then
		onCharacterAdded(character)
	end
	
	return function()
		for id, con in pairs(cons) do
			con:Disconnect()
			cons[id] = nil
		end
	end
end

function Effects.instance(getter, added, removed)
    return function(instance, add, remove, context)
        for _, item in pairs(instance[getter](instance)) do
            add(item, context)
        end

        local conAdded = instance[added]:Connect(function(item)
            add(item, context)
        end)
        local conRemoved = instance[removed]:Connect(remove)

        return function()
            conAdded:Disconnect()
            conRemoved:Disconnect()
        end
    end
end

function Effects.call(item, effect)
    return effect(item, function() end, function() end)
end

return Effects