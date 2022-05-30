local Bin = {}
Bin.__index = Bin

type taskId = string | table

local TYPE_TO_DESTRUCT_METHOD = {
	["function"] = function(task)
		return task
	end;
	["thread"] = function(_task)
		return coroutine.close
	end;
	["table"] = function(task)
		return task.Destroy
	end;
	["RBXScriptConnection"] = function(task)
		return task.Disconnect
	end;
	["Instance"] = function(task)
		return task.Destroy
	end;
	["nil"] = function()
		error("Task cannot be nil")
	end;
}

function Bin.new()
	return setmetatable({}, Bin)
end

function Bin.is(value)
	return type(value) == "table" and getmetatable(value) == Bin
end

-- Cleans and clears all tasks within the bin.
function Bin:Destroy(...)
	local index = next(self)

	-- Removes all tasks from the bin. next(tbl) without the key ensures
	-- any tasks added to the bin during cleaning will be caught.
	while index ~= nil do
		self:Remove(index, ...)
		index = next(self)
	end
end
Bin.DoCleaning = Bin.Destroy

-- Adds a task to the bin.
-- If using id argument and it already exists, the task will be cleaned, unless the old task is equal to the new.
function Bin:GiveTask<taskId>(task, destructorName: string?, id)
	assert(task ~= self, "Cannot add a bin to itself")

	local resolvedDestruct = 
		if destructorName then task[destructorName]
		else TYPE_TO_DESTRUCT_METHOD[typeof(task)](task)
	
	if resolvedDestruct == nil then
		error(("Task type %q does not have a destruct function"):format(typeof(task)), 2)
	end

	local oldTask = id and rawget(self, id)
	if oldTask and task == oldTask.task then
		return
	end

	if oldTask then
		self:Remove(id)
	end

	local entry = table.freeze({task = task, destruct = resolvedDestruct})
	local resolvedId = id or entry
	self[resolvedId] = entry

	return resolvedId
end

-- Declarative sugar.
function Bin:Add<table, taskId>(task, destructorName: string?, id)
	local taskId = self:GiveTask(task, destructorName, id)
	return task, taskId
end

-- Declarative sugar. Same as :Add but destructor name is default.
function Bin:AddId<table, taskId>(task, id)
	local taskId = self:GiveTask(task, nil, id)
	return task, taskId
end

-- Declarative sugar for adding multiple tasks in a go.
function Bin:GiveTasks<Bin, table>(tasks: table)
	local ids = {}
	for key, task in pairs(tasks) do
		if type(key) == "number" then
			ids[self:GiveTask(task)] = task
		else
			ids[self:GiveTask(task, nil, key)] = task
		end
	end

	return self, ids
end

function Bin:AddPromise(promise: table, id)
	if promise:getStatus() == "Started" then
		local resolvedId = self:GiveTask(promise, "cancel", id)

		promise:finally(function()
			self[resolvedId] = nil
		end)
	end

	return promise
end

-- Removes and cleans a task from the bin.
function Bin:Remove(taskId: taskId, ...)
	local entry = rawget(self, taskId)
	if entry == nil then
		return
	end

	self[taskId] = nil

	if entry.destruct == entry.task then
		return entry.destruct(...)
	else
		return entry.destruct(entry.task, ...)
	end
end

export type Bin = typeof(Bin.new())

return Bin