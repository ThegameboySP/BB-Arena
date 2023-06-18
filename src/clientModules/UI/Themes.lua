local function darkmode(theme)
	theme.title = Color3.fromRGB(231, 231, 231)
	theme.text = Color3.fromRGB(196, 196, 196)
	theme.highContrast = Color3.fromRGB(255, 255, 255)

	theme.background = Color3.fromRGB(16, 17, 19)
	theme.foreground = Color3.fromRGB(29, 31, 35)
	theme.scrollbar = Color3.fromRGB(117, 117, 117)
	theme.inactive = Color3.fromRGB(117, 117, 117)
	theme.border = Color3.fromRGB(55, 59, 66)

	return theme
end

local Themes = {
	Purple = darkmode({
		accent = Color3.fromRGB(186, 104, 200),
		button = Color3.fromRGB(186, 104, 200),
		lessImportantButton = Color3.fromRGB(143, 86, 154),
	}),
	HotPink = darkmode({
		accent = Color3.fromRGB(255, 104, 200),
		button = Color3.fromRGB(211, 98, 174),
		lessImportantButton = Color3.fromRGB(177, 96, 145),
	}),
	Blue = darkmode({
		accent = Color3.fromRGB(62, 149, 216),
		button = Color3.fromRGB(50, 118, 150),
		lessImportantButton = Color3.fromRGB(33, 35, 39),
	}),
	Red = darkmode({
		accent = Color3.fromRGB(216, 62, 57),
		button = Color3.fromRGB(161, 44, 42),
		lessImportantButton = Color3.fromRGB(33, 35, 39),
	}),
}

Themes.default = Themes.Blue

return Themes
