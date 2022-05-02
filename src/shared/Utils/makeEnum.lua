local function makeEnum(name, tbl)
    return table.freeze(setmetatable(tbl, {__index = function(_, key)
        error(("%s is not a valid member of %q"):format(key, name), 2)
    end}))
end

return makeEnum