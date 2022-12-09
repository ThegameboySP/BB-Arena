local Components = {}

for _, child in script:GetChildren() do
	Components[child.Name] = require(child)
end

return Components
