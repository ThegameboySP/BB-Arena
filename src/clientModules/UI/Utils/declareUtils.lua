local function doThis(fn)
	return fn()
end

local NumberAdvancer = {}
NumberAdvancer.__index = NumberAdvancer

function NumberAdvancer.new(number)
	return setmetatable({ number = number or 0 }, NumberAdvancer)
end

function NumberAdvancer:add(addition)
	self.number += addition
	return self.number
end

function NumberAdvancer:advance(addition)
	self.number += addition
	return addition
end

function NumberAdvancer:set(to)
	self.number = to
	return to
end

return {
	NumberAdvancer = NumberAdvancer,
	doThis = doThis,
}
