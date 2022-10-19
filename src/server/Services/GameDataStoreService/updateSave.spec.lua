local updateSave = require(script.Parent.updateSave)

return function()
    it("should update with no existing stats", function()
        local updatedSave = updateSave({
            stats = {
                KOs = 3;
                WOs = 2;
            };
        })

        expect(updatedSave.stats.KOs).to.equal(3)
        expect(updatedSave.stats.WOs).to.equal(2)
    end)

    it("should update with existing stats, adding numbers", function()
        local updatedSave = updateSave({
            stats = {
                KOs = 3;
                WOs = 2;
            };
        }, {
            stats = {
                KOs = 1;
                WOs = 1;
            }
        })

        expect(updatedSave.stats.KOs).to.equal(4)
        expect(updatedSave.stats.WOs).to.equal(3)
    end)
end