return function (context, mapName)
	context:GetStore("Common").Knit.GetService("MapService"):ChangeMap(mapName)
end