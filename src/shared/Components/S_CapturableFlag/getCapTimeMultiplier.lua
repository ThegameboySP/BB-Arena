return function(groups)
	if groups == 0 or groups == 1 then
		return 1
	elseif groups == 2 then
		return 1.8
	elseif groups == 3 then
		return 2.3
	elseif groups >= 4 then
		return 2.6
	end
end