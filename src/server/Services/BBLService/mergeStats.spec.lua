local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Llama = require(ReplicatedStorage.Packages.Llama)
local mergeStats = require(script.Parent.mergeStats)

local Dictionary = Llama.Dictionary

return function()
    it("should merge with no existing stats", function()
        expect(Dictionary.equalsDeep(
            mergeStats(nil, {
                KOs = {["1"] = 1, ["2"] = 2}, WOs = {["1"] = 1, ["2"] = 2}
            }),
            {KOs = {["1"] = 1, ["2"] = 2}, WOs = {["1"] = 1, ["2"] = 2}}
        )).to.equal(true)
    end)

    it("should merge with existing stats, adding numbers", function()
        expect(Dictionary.equalsDeep(
            mergeStats({
                KOs = {["1"] = 1, ["2"] = 0}, WOs = {["1"] = 2, ["2"] = 1}
            }, {
                KOs = {["1"] = 1, ["2"] = 1}, WOs = {["1"] = 1, ["2"] = 1}
            }),
            {KOs = {["1"] = 2, ["2"] = 1}, WOs = {["1"] = 3, ["2"] = 2}}
        )).to.equal(true)
    end)
end