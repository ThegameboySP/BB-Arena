local Components = {}

for _, child in script:GetChildren() do
	Components[child.Name] = require(child)
end

return table.freeze(setmetatable(Components, {
	__index = function(_, k)
		error(("%q is not a valid Component"):format(k), 2)
	end,
}))
