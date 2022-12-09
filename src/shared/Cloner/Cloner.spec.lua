local CollectionService = game:GetService("CollectionService")

local Cloner = require(script.Parent)

return function()
	local parent
	local prototypes
	local cloner
	beforeEach(function()
		parent = Instance.new("Folder")
		local prototype1 = Instance.new("Part")
		prototype1.Parent = parent
		local prototype2 = Instance.new("Part")
		prototype2.Parent = prototype1

		CollectionService:AddTag(prototype1, "tag1")
		CollectionService:AddTag(prototype1, "tag2")
		CollectionService:AddTag(prototype2, "tag2")

		prototypes = { prototype1, prototype2 }
		cloner = Cloner.new({ [prototype1] = { tag1 = true, tag2 = true }, [prototype2] = { tag1 = true } })
	end)

	afterEach(function()
		cloner:Destroy()
	end)

	it("should deparent prototypes and clone them", function()
		expect(prototypes[1].Parent).to.equal(nil)
		expect(prototypes[2].Parent).to.equal(nil)
		cloner:RunPrototypes(prototypes)

		expect(parent:FindFirstChild("Part"):FindFirstChild("Part")).to.be.ok()
	end)

	it("should despawn clone tree and create a new one", function()
		cloner:RunPrototypes(prototypes)
		cloner:DespawnClone(parent:FindFirstChild("Part"))
		cloner:RunPrototypes({ prototypes[1] })

		expect(parent:FindFirstChild("Part"):FindFirstChild("Part")).to.be.ok()
	end)
end
