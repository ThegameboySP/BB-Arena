local RichText = {}

local function colorToString(color)
	if type(color) == "string" then
		return color
	end

	return table.concat({
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255),
	}, ",")
end

function RichText.color(str, color)
	return '<font color="rgb(' .. colorToString(color) .. ')">' .. str .. "</font>"
end

function RichText.font(str, font)
	return '<font face="' .. font .. '">' .. str .. "</font>"
end

function RichText.size(str, size)
	return '<font size="' .. tostring(size) .. '">' .. str .. "</font>"
end

function RichText.bold(str)
	return "<b>" .. str .. "</b>"
end

function RichText.italicize(str)
	return "<i>" .. str .. "</i>"
end

function RichText.strikethrough(str)
	return "<s>" .. str .. "</s>"
end

function RichText.underline(str)
	return "<u>" .. str .. "</u>"
end

function RichText.smallcaps(str)
	return "<sc>" .. str .. "</sc>"
end

return RichText
