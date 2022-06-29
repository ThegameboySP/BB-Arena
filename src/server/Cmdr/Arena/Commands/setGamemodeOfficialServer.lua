return function(context, isOfficial)
    local BBLService = context:GetStore("Common").Root:GetService("BBLService")

    BBLService:SetGamemodeOfficial(isOfficial)

    if isOfficial then
        return "Forced current gamemode to be official"
    else
        return "Forced current gamemode to be unofficial"
    end
end