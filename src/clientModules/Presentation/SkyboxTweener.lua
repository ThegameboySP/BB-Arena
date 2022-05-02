local SkyboxTweener = {}
SkyboxTweener.__index = SkyboxTweener

function SkyboxTweener.new()
    return setmetatable({

    }, SkyboxTweener)
end

function SkyboxTweener:SetSkybox()

end

function SkyboxTweener:Finish()

end

return SkyboxTweener