return function()
	if workspace:FindFirstChild("CmdrMusic") then
		workspace.CmdrMusic:Destroy()
        return "Stopped music"
	end
	
	return "No music is playing"
end