local CollectionService = game:GetService("CollectionService")

local function getAncestorPrototype(prototypesMap, instance)
    local current = instance.Parent
    while current do
        if prototypesMap[current] then
            return current
        end

        current = current.Parent
    end
end

local Cloner = {}
Cloner.__index = Cloner

function Cloner.new(matchedTagsByPrototype, onClonesAdded, onCloneRemoved)
    local self = setmetatable({
        _onClonesAdded = onClonesAdded or function() end;
        _onCloneRemoved = onCloneRemoved or function() end;

        _prototypeToClone = {};
        _prototypeRecordByPrototype = {};
        _cloneRecordByClone = {};
    }, Cloner)

    for prototype, matchedTags in pairs(matchedTagsByPrototype) do
        self._prototypeRecordByPrototype[prototype] = {
            prototype = prototype;
            tagsMap = table.freeze(matchedTags);
            parent = prototype.Parent;
            descendantPrototypes = {};
            ancestorPrototype = nil;
        }
    end

    for prototype in pairs(matchedTagsByPrototype) do
        local ancestor = getAncestorPrototype(matchedTagsByPrototype, prototype)
        
        if ancestor then
            self._prototypeRecordByPrototype[prototype].ancestorPrototype = ancestor
            table.insert(self._prototypeRecordByPrototype[ancestor].descendantPrototypes, prototype)
        end
    end

    for prototype in pairs(matchedTagsByPrototype) do
        prototype.Parent = nil
    end

    return self
end

function Cloner:Destroy()
    assert(next(self), "Cloner is already destroyed!")

    self:DespawnAll()

    for _, prototypeRecord in pairs(self._prototypeRecordByPrototype) do
        prototypeRecord.prototype.Parent = prototypeRecord.parent
    end

    table.clear(self)
end

-- Separate from Destroy so server can replicate deparenting clones before map change
-- (or else automatic replication won't know to clear the old clones)
function Cloner:DespawnAll()
    local clonesToDestroy = table.clone(self._cloneRecordByClone)
    for clone in pairs(clonesToDestroy) do
        self:DespawnClone(clone)
    end
end

function Cloner:GetPrototypes(filter)
    filter = filter or function()
        return true
    end

    local prototypes = {}
    for prototype, record in pairs(self._prototypeRecordByPrototype) do
        if filter(record) then
            table.insert(prototypes, prototype)
        end
    end

    return prototypes
end

function Cloner:RunPrototypes(selector)
    local prototypes = selector
    
    if type(selector) == "nil" then
        selector = function()
            return true
        end
    end

    if type(selector) == "function" then
        prototypes = self:GetPrototypes(selector)
    end
    
    local cloneRecords = {}
    for _, prototype in ipairs(prototypes) do
        if self._prototypeToClone[prototype] then
            continue
        end
        
        -- Automatically include all descendant prototypes when running.
        for _, thisPrototype in ipairs({prototype, unpack(self._prototypeRecordByPrototype[prototype].descendantPrototypes)}) do
            if not self._prototypeToClone[thisPrototype] then
                local clone = thisPrototype:Clone()
                self._prototypeToClone[thisPrototype] = clone
                
                local prototypeRecord = self._prototypeRecordByPrototype[thisPrototype]

                for tag in pairs(prototypeRecord.tagsMap) do
                    CollectionService:RemoveTag(clone, tag)
                end
                
                local cloneRecord = table.freeze({
                    prototypeRecord = prototypeRecord;
                    clone = clone;
                })

                self._cloneRecordByClone[clone] = cloneRecord
                table.insert(cloneRecords, cloneRecord)
            end
        end
    end

    local clonesAdded = {}
    for _, cloneRecord in ipairs(cloneRecords) do
        if cloneRecord.prototypeRecord.ancestorPrototype then
            cloneRecord.clone.Parent = self._prototypeToClone[cloneRecord.prototypeRecord.ancestorPrototype]
        else
            cloneRecord.clone.Parent = cloneRecord.prototypeRecord.parent
        end

        table.insert(clonesAdded, {
            clone = cloneRecord.clone;
            tagsMap = cloneRecord.prototypeRecord.tagsMap;
        })
    end

    self._onClonesAdded(clonesAdded)
end

function Cloner:ContainsClone(clone)
    return if self._cloneRecordByClone[clone] then true else false
end

function Cloner:ContainsPrototype(prototype)
    return if self._prototypeRecordByPrototype[prototype] then true else false
end

function Cloner:DespawnClone(clone)
    if not self:ContainsClone(clone) then
        return
    end

    local cloneRecord = self._cloneRecordByClone[clone]
    for _, descendantPrototype in pairs(cloneRecord.prototypeRecord.descendantPrototypes) do
        local descendantClone = self._prototypeToClone[descendantPrototype]

        if descendantClone then
            self:DespawnClone(descendantClone)
        end
    end

    self._prototypeToClone[cloneRecord.prototypeRecord.prototype] = nil
    self._cloneRecordByClone[clone] = nil
    clone.Parent = nil

    self._onCloneRemoved(clone, cloneRecord.prototypeRecord.tagsMap)
end

function Cloner:GetPrototypeByClone(clone)
    local cloneRecord = self._cloneRecordByClone[clone]
    if cloneRecord == nil then
        error(("Cloner does not contain %s. Use :ContainsClone if needed."):format(clone:GetFullName()))
    end

    return cloneRecord.prototypeRecord.prototype
end

function Cloner:GetCloneByPrototype(clone)
    if not self:ContainsPrototype(clone) then
        error(("Cloner does not contain %s. Use :ContainsPrototype if needed."):format(clone:GetFullName()))
    end

    return self._prototypeToClone[clone]
end

return Cloner