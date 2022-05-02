local CollectionService = game:GetService("CollectionService")

local function getAncestorPrototype(prototypesMap, instance)
    local current = instance.Parent
    while current do
        if prototypesMap[current] then
            return current
        end

        current = instance.Parent
    end
end

local Cloner = {}
Cloner.__index = Cloner

function Cloner.new(tags, prototypes, onCloneAdded, onCloneRemoved)
    local self = setmetatable({
        _onCloneAdded = onCloneAdded or function() end;
        _onCloneRemoved = onCloneRemoved or function() end;

        _prototypeToClone = {};
        _prototypeRecordByPrototype = {};
        _cloneRecordByClone = {};
    }, Cloner)

    local matchedTagsByPrototype = {}
    for _, prototype in pairs(prototypes) do
        local matchedTags = {}

        for _, tag in pairs(CollectionService:GetTags(prototype)) do
            if tags[tag] then
                matchedTags[tag] = true
            end
        end

        if matchedTags[1] then
            matchedTagsByPrototype[prototype] = matchedTags
        end
    end

    for prototype, matchedTags in pairs(matchedTagsByPrototype) do
        self._prototypeRecordByPrototype[prototype] = table.freeze({
            prototype = prototype;
            tagsMap = table.freeze(matchedTags);
            parent = prototype.Parent;
            ancestorPrototype = getAncestorPrototype(matchedTagsByPrototype, prototype);
        })

        prototype.Parent = nil
    end

    return self
end

function Cloner:Destroy()
    assert(next(self), "Cloner is already destroyed!")

    for clone in pairs(self._cloneRecordByClone) do
        self:DespawnClone(clone)
    end

    for _, prototypeRecord in pairs(self._prototypeRecordByPrototype) do
        prototypeRecord.prototype.Parent = prototypeRecord.parent
    end

    table.clear(self)
end

function Cloner:RunPrototypes(selector)
    local prototypes = {}

    if type(selector) == "function" then
        for prototype in pairs(self._prototypeRecordByPrototype) do
            if selector(prototype) then
                table.insert(prototypes, prototype)
            end
        end
    elseif type(selector) == "table" then
        prototypes = selector
    end

    local cloneRecords = {}
    for _, prototype in ipairs(prototypes) do
        if not self._prototypeToClone[prototype] then
            local clone = prototype:Clone()
            self._prototypeToClone[prototype] = clone
            
            local prototypeRecord = self._prototypeRecordByPrototype[prototype]

            for tag in pairs(prototypeRecord.tagsMap) do
                CollectionService:RemoveTag(clone, tag)
            end
            
            table.insert(cloneRecords, table.freeze({
                prototypeRecord = prototypeRecord;
                clone = clone;
            }))
        end
    end

    for _, cloneRecord in ipairs(cloneRecords) do
        if cloneRecord.prototypeRecord.ancestorPrototype then
            cloneRecord.clone.Parent = self._prototypeToClone[cloneRecord.prototypeRecord.ancestorPrototype]
        else
            cloneRecord.clone.Parent = cloneRecord.prototypeRecord.parent
        end

        self._onCloneAdded(cloneRecord.clone, cloneRecord.prototypeRecord.tagsMap)
    end
end

function Cloner:ContainsClone(clone)
    return if self._cloneRecordByClone[clone] then true else false
end

function Cloner:ContainsPrototype(prototype)
    return if self._prototypeRecordByPrototype[prototype] then true else false
end

function Cloner:DespawnClone(clone)
    if not self:ContainsClone(clone) then
        error(("Cloner does not contain %s. Use :ContainsClone if needed."):format(clone:GetFullName()))
    end

    local cloneRecord = self._cloneRecordByClone[clone]
    self._prototypeToClone[cloneRecord.prototypeRecord.prototype] = nil
    self._cloneRecordByClone[clone] = nil
    clone:Destroy()

    self._onCloneRemoved(clone, cloneRecord.prototypeRecord.tagsMap)
end

function Cloner:GetPrototypeByClone(clone)
    local cloneRecord = self._cloneRecordByClone[clone]
    if cloneRecord == nil then
        error(("Cloner does not contain %s. Use :ContainsPrototype if needed."):format(clone:GetFullName()))
    end

    return cloneRecord.prototypeRecord.prototype
end

return Cloner