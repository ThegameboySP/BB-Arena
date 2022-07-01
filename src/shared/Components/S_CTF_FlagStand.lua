local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local t = require(ReplicatedStorage.Packages.t)
local Component = require(ReplicatedStorage.Common.Component).Component
local General = require(ReplicatedStorage.Common.Utils.General)

local S_CTF_FlagStand = Component:extend("CTF_FlagStand", {
    realm = "server";
    
    checkConfiguration = t.strictInterface({
        TeamColor = t.BrickColor;
    });
    checkInstance = t.instanceIsA("BasePart");
})

local function getTeamByColor(color)
	for _, team in ipairs(Teams:GetTeams()) do
		if team.TeamColor == color then
			return team
		end
	end
end

function S_CTF_FlagStand:OnInit()
    local flag = self.Instance:FindFirstChild("Flag")
    if flag == nil then
        task.spawn(error, "Could not find flag under " .. self.Instance:GetFullName())
        return
    end

	self:SetState({
		Team = getTeamByColor(self.Config.TeamColor);
		Flag = flag;
	})
end

function S_CTF_FlagStand:OnStart()
    self.Instance.Touched:Connect(function(part)
        local character = General.getCharacterFromHitbox(part)
        if not character or not General.isValidCharacter(character) then
            return
        end

        local player = Players:GetPlayerFromCharacter(character)

        local characterFlagComponent = self.Manager:GetComponent(character:FindFirstChild("Flag"), "CTF_Flag")
        if not characterFlagComponent then
            return
        end

        if player.Team == self.State.Team then
            if characterFlagComponent.State.Team == self.State.Team then
                characterFlagComponent:OnReturn(player)
            else
                characterFlagComponent:OnTouchdown(player)
            end
        end
    end)
end

return S_CTF_FlagStand