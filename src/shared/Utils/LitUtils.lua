local LitUtils = {}

function LitUtils.getIndefiniteArticle(text)
    local firstLetter = string.lower(string.sub(text, 1, 1))

    return 
        if firstLetter == "a"
            or firstLetter == "e"
            or firstLetter == "i"
            or firstLetter == "o"
            or firstLetter == "u"
        then "an"
        else "a"
end

function LitUtils.arrayToSubject(nouns)
	if #nouns > 2 then
		return table.concat(nouns, ", ", 1, #nouns - 1)
			.. ", and "
			.. nouns[#nouns] 
	elseif #nouns == 2 then
		return nouns[1] .. " and " .. nouns[2]
	end

	return nouns[1] or ""
end

return LitUtils