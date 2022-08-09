local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

local Cage = script.Parent.Cage

local Promise = require(ReplicatedStorage.Packages.Promise)
local Bin = require(ReplicatedStorage.Common.Utils.Bin)
local LitUtils = require(ReplicatedStorage.Common.Utils.LitUtils)
local RichText = require(ReplicatedStorage.Common.Utils.RichText)
local makeEnum = require(ReplicatedStorage.Common.Utils.makeEnum)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)

local strings = {
    waiting = "Waiting for %s team%s to be filled";
    extraLifeTeamChange = "%s was manually teamed from the %s team to %s, getting an extra life";
    extraLifeSameTeam = "%s was manually teamed back to the %s team, getting an extra life";
    teamChange = "%s is now under the %s team";
    teamLeft = "%s is no longer under the %s team";
    toDeadTeam = "%s somehow got moved to the dead team";
    tie = "There was a tie!";
    win = "The %s team won the round!";
    wonGame = "The %s team has won the game!";

    winTagTiesCount = "Everyone gets a point since Ties Count is enabled";
    winTagWb2 = "Continuing since Win By Two is enabled";
    winTagTied = "Continuing since the teams are tied";
}

local GameState = makeEnum("GameState", {
    Tied = 0;
    TeamWon = 1;
    WinByTwo = 2;
    NoWinner = 3;
})

local function count(t)
    local n = 0
    for _ in t do
        n += 1
    end

    return n
end

local function makeTimer(seconds)
    local timestamp = os.clock()

    return function()
        return (os.clock() - timestamp) >= seconds
    end
end

local Scrimmage = {}
Scrimmage.UpdateEvent = RunService.Heartbeat
Scrimmage.__index = Scrimmage

function Scrimmage.new(service)
    return setmetatable({
        service = service;
        bin = Bin.new();
        -- Map of player -> fighter info. Only sets in GameRunning.
        fightingPlayers = {};
        -- Map of character -> character info. Only sets in GameRunning.
        fightingCharacters = {};

        promise = Promise.resolve();
    }, Scrimmage)
end

function Scrimmage:OnConfigChanged(config)
    config.maxScore = math.max(1, config.maxScore)
    self.config = config
    
    self.replicatedRoot:SetAttribute("MaxScore", config.maxScore)
    self.replicatedRoot:SetAttribute("WinByTwo", config.winByTwo)
    self.replicatedRoot:SetAttribute("TiesCount", config.tiesCount)

    for _, team in self.fightingTeams do
        self.replicatedRoot:SetAttribute(team.Name, self:getTeamScore(team) or 0)
    end

    self:_finishIfWinningTeam()
end

function Scrimmage:OnScoresSet(scoresByTeam)
    for team, score in scoresByTeam do
        if table.find(self.fightingTeams, team) then
            self.replicatedRoot:SetAttribute(team.Name, score)
        end
    end

    self:_finishIfWinningTeam()
end

function Scrimmage:OnMapChanged(oldTeamToNewTeam)
    local scoresByTeam = {}
    for _, team in self.fightingTeams do
        scoresByTeam[oldTeamToNewTeam[team]] = self:getTeamScore(team)
        self.replicatedRoot:SetAttribute(team.Name, nil)
    end
    
    local newTeams = {}
    for _, team in oldTeamToNewTeam do
        self.replicatedRoot:SetAttribute(team.Name, scoresByTeam[team] or 0)
        table.insert(newTeams, team)
    end

    self.fightingTeams = newTeams

    for player, data in self.fightingPlayers do
        local newTeam = oldTeamToNewTeam[data.team]
        print("[Scrimmage]", data.team, "->", newTeam)

        if newTeam then
            data.team = newTeam
        else
            self.fightingPlayers[player] = nil
        end
    end

    for _, data in self.fightingCharacters do
        self.fightingPlayers[data.player].startingHealth = data.humanoid.Health
    end

    self:changeState("GamePaused")
end

function Scrimmage:OnInit(config, fightingTeams)
    self.fightingTeams = fightingTeams

    self.replicatedRoot = Instance.new("Folder")
    self.replicatedRoot.Name = "Scrimmage_ReplicatedRoot"
    self.replicatedRoot.Parent = ReplicatedStorage

    self:OnConfigChanged(config)

    self.deadTeam = Instance.new("Team")
    self.deadTeam.Name = "Dead"
    self.deadTeam.AutoAssignable = false
    self.deadTeam.TeamColor = BrickColor.Black()
    self.deadTeam.Parent = Teams

    self.cage = Cage:Clone()
    self.cage.Parent = Workspace
    self.awayCFrame = self.cage.Floor.CFrame * CFrame.new(0, 3, 0)
    
    self:changeState("GamePaused")
end

function Scrimmage:Destroy()
    local teams = table.clone(self.fightingTeams)
    table.insert(teams, self.deadTeam)

    for _, team in teams do
        for _, player in team:GetPlayers() do
            local data = self.fightingPlayers[player]
            if data then
                player.Team = data.team
            else
                player.Team = Teams.Spectators
            end

            task.spawn(player.LoadCharacter, player)
        end
    end
    
    self.deadTeam.Parent = nil
    self.replicatedRoot.Parent = nil
    self.cage.Parent = nil

    self.promise:cancel()
    self.bin:DoCleaning()
end

function Scrimmage:_formatWonGame(winningTeam, fightingTeams)
    local scores = {}
    for _, team in fightingTeams do
        table.insert(scores, {team = team, score = self:getTeamScore(team)})
    end

    table.sort(scores, function(a, b)
        return a.score > b.score
    end)

    local scoreStrings = {}
    for _, data in ipairs(scores) do
        table.insert(scoreStrings, string.format("%s team: %d", data.team.Name, data.score))
    end

    return
        RichText.color(string.format(strings.wonGame, winningTeam.Name) .. "\n", winningTeam.TeamColor.Color)
        .. RichText.color(table.concat(scoreStrings, "\n"), Color3.new(1, 1, 1))
end

function Scrimmage:finishGame(winningTeam)
    self.service:AnnounceEvent(self:_formatWonGame(winningTeam, self.fightingTeams), {
        stayOpen = true;
    })

    self.service:StopGamemode(true)
end

function Scrimmage:announce(msg)
    print("[Scrimmage]", msg)
    self.service:SayEvent(msg)
end

function Scrimmage:changeState(state, ...)
    print("[Scrimmage]", self.state, "->", state)

    self.promise:cancel()
    self.bin:DoCleaning()
    self.state = state

    task.spawn(self[state], self, ...)
end

function Scrimmage:enoughPlayers(ignoreCache)
    local occupiedTeams = {}

    for _, team in self.fightingTeams do
        if #team:GetPlayers() > 0 then
            occupiedTeams[team] = true
        end
    end

    for player, data in self.fightingPlayers do
        if not ignoreCache or player.Team == self.deadTeam then
            occupiedTeams[data.team] = true
        end
    end

    return count(occupiedTeams) == #self.fightingTeams
end

function Scrimmage:_resolveWinner()
    local scores = {}
    for _, team in self.fightingTeams do
        table.insert(scores, {
            score = self:getTeamScore(team);
            team = team;
        })
    end

    table.sort(scores, function(a, b)
        return a.score > b.score
    end)

    if not self.config.winByTwo and scores[1].score >= self.config.maxScore then
        if scores[1].score == scores[2].score then
            return GameState.Tied
        else
            return GameState.TeamWon, scores[1].team
        end
    elseif self.config.winByTwo then
        if (scores[1].score - scores[2].score) >= 2 then
            return GameState.TeamWon, scores[1].team
        else
            return GameState.WinByTwo
        end
    end

    return GameState.NoWinner
end

function Scrimmage:_finishIfWinningTeam()
    local _, winner = self:_resolveWinner()

    if winner then
        self:finishGame(winner)
        return true
    end
    
    return false
end

function Scrimmage:GamePaused(condition, reason)
    if reason then
        self:announce("Game is paused. Reason: " .. reason)
    end

    if self:_finishIfWinningTeam() then
        return
    end

    for player, data in self.fightingPlayers do
        player.Team = data.team
    end

    local function onFightingPlayerAdded(player)
        local data = self.fightingPlayers[player]
        
        if (not data or data.isDead) or not self:enoughPlayers() then
            self.bin:AddId(self:putPlayerAway(player), player)
        end
    end

    for _, team in self.fightingTeams do
        self.bin:Add(team.PlayerAdded:Connect(onFightingPlayerAdded))
        self.bin:Add(team.PlayerRemoved:Connect(function(player)
            self.bin:Remove(player)
            player:LoadCharacter()
        end))

        for _, player in team:GetPlayers() do
            onFightingPlayerAdded(player)
        end
    end

    local waitingForTeams = {}
    
    self.bin:Add(Scrimmage.UpdateEvent:Connect(function()
        if not self:enoughPlayers() then
            local teamSizes = {}
            local teamsToAnnounceWaitingFor = {}

            for _, team in self.fightingTeams do
                local size = #team:GetPlayers()
                teamSizes[team] = size
                
                if size == 0 then
                    table.insert(teamsToAnnounceWaitingFor, team.Name)
                end
            end

            local changeOccurred = false
            for team, size in teamSizes do
                local oldSize = waitingForTeams[team]

                if oldSize ~= size and (size == 0 or oldSize == 0 or oldSize == nil) then
                    changeOccurred = true    
                    break
                end
            end

            waitingForTeams = teamSizes

            if changeOccurred and teamsToAnnounceWaitingFor[1] then
                self:announce(string.format(
                    strings.waiting,
                    LitUtils.arrayToSubject(teamsToAnnounceWaitingFor),
                    teamsToAnnounceWaitingFor[2] and "s" or ""
                ))
            end

        elseif condition == nil or condition() then
            self:changeState("GameRunning")
        end
    end))
end

function Scrimmage:GameRunning()
    local playersToRespawn = {}
    local fightingCharacters = {}
    self.fightingCharacters = fightingCharacters

    self.service.MapService:Regen()

    for _, team in self.fightingTeams do
        local function onPlayerAdded(player)
            local data = self.fightingPlayers[player]

            self.fightingPlayers[player] = {
                team = team;
                startingHealth = data and data.startingHealth or 100;
                isDead = false;
                character = nil;
                humanoid = nil;
            }
        end

        for _, player in team:GetPlayers() do
            onPlayerAdded(player)
        end

        local connection
        connection = self.bin:Add(team.PlayerAdded:Connect(function(player)
            local data = self.fightingPlayers[player]

            if not data or data.team ~= team or data.isDead then
                -- Remove automatic repositioning for this player, if he's died.
                self.bin:Remove(player)
                
                local characterData = fightingCharacters[player.Character]
                local startingHealth = 100
                if characterData then
                    startingHealth = characterData.humanoid.Health
                end

                player:LoadCharacter()

                -- Recheck the conditions since LoadCharacter yields the thread.
                if connection.Connected and player.Team == team then
                    local refreshedData = self.fightingPlayers[player] or data

                    if data and data.isDead then
                        if refreshedData.team == team then
                            self:announce(string.format(strings.extraLifeSameTeam, getFullPlayerName(player), team.Name))
                        else
                            self:announce(string.format(strings.extraLifeTeamChange, getFullPlayerName(player), data.team.Name, team.Name))
                        end
                    else
                        self:announce(string.format(strings.teamChange, getFullPlayerName(player), team.Name))
                    end

                    onPlayerAdded(player)

                    self.fightingPlayers[player].startingHealth = startingHealth
                end
            end
        end))
    end

    for player, data in self.fightingPlayers do
        if player.Parent and (player.Team == data.team or player.Team == self.deadTeam) then
            data.isDead = false
            player.Team = data.team

            table.insert(playersToRespawn, player)
        else
            self.fightingPlayers[player] = nil
        end
    end

    self:loadCharacters(playersToRespawn):await()

    self.bin:Add(Scrimmage.UpdateEvent:Connect(function()
        for player, data in self.fightingPlayers do
            if
                not player.Parent
                or (not data.isDead and player.Team ~= data.team)
                or (data.isDead and player.Team ~= self.deadTeam)
            then
                -- Remove automatic repositioning for this player, if he's died.
                self.bin:Remove(player)

                self.fightingPlayers[player] = nil

                if data.character then
                    fightingCharacters[data.character] = nil
                end
                
                self:announce(string.format(strings.teamLeft, getFullPlayerName(player), data.team.Name))
            end
        end

        if self.promise:getStatus() == Promise.Status.Started then
            return
        end

        if not self:enoughPlayers(true) then
            self:changeState("GamePaused")
            return
        end

        for player, data in self.fightingPlayers do
            local character = player.Character

            if
                not data.isDead
                and character and not fightingCharacters[character]
                and ((data.character and data.humanoid.Health > 0) or not data.character)
            then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid == nil then
                    continue
                end

                if data.character then
                    fightingCharacters[data.character] = nil
                end

                data.character = character
                data.humanoid = humanoid

                humanoid.Health = data.startingHealth

                fightingCharacters[character] = {
                    player = player;
                    character = character;
                    humanoid = humanoid;
                }
            end
        end

        local nonEmptyTeams = {}

        for character, data in fightingCharacters do
            if
                data.humanoid.Health <= 0
                or not character.Parent
                or data.player.Team == self.deadTeam
            then
                -- Ensure any players that respawned don't have multiple characters.
                if not character.Parent then
                    fightingCharacters[character] = nil

                    -- If a player is respawning, it's assumed the new character should exist when the old is deparented.
                    if self.fightingPlayers[data.player].character ~= character then
                        continue
                    end
                end

                if data.player.Team == self.deadTeam then
                    data.humanoid.Health = 0
                    
                    self:announce(string.format(
                        strings.toDeadTeam,
                        getFullPlayerName(data.player)
                    ))
                end

                self.bin:AddId(self:putPlayerAway(data.player, character), data.player)
                fightingCharacters[character] = nil

                self.fightingPlayers[data.player].isDead = true
                data.player.Team = self.deadTeam
            else
                nonEmptyTeams[data.player.Team] = true
            end
        end

        if (#self.fightingTeams - count(nonEmptyTeams)) >= 1 then
            -- Sample health right now. Otherwise, it's prone to players resetting
            -- to clear their health.
            local startingHealth = {}
            for _, data in fightingCharacters do
                startingHealth[data.player] = data.humanoid.Health
            end

            self.promise = self:resolveGameState()
                :andThen(function(fn)
                    if fn then
                        local message = fn()
                        if message then
                            self:announce(message)
                        end
                    end

                    -- Be sure to reset startingHealth if the player had already died.
                    for player, data in self.fightingPlayers do
                        data.startingHealth = startingHealth[player] or 100
                    end

                    self:changeState("GamePaused", makeTimer(2))
                end)
                :catch(warn)
        end
    end))
end

function Scrimmage:resolveGameState()
    return self:checkForTie():andThen(function(winningTeam)
        local isTied = winningTeam == nil

        return Promise.resolve(function()
            local tags = {}

            if isTied then
                table.insert(tags, strings.tie)

                if self.config.tiesCount then
                    tags[1] ..= " " .. strings.winTagTiesCount

                    for _, team in self.fightingTeams do
                        self:addPointToTeam(team)
                    end
                end
            else
                table.insert(tags, strings.win:format(winningTeam.Name))
                self:addPointToTeam(winningTeam)
            end

            local gameState, gameWinningTeam = self:_resolveWinner()

            if gameState == GameState.TeamWon then
                return strings.wonGame:format(gameWinningTeam.Name)
            elseif gameState == GameState.WinByTwo then
                table.insert(tags, strings.winTagWb2)
            elseif gameState == GameState.Tied then
                table.insert(tags, strings.winTagTied)
            end

            return table.concat(tags, "\n") .. if tags[2] then "." else ""
        end)
    end)
end

function Scrimmage:addPointToTeam(team)
    self.replicatedRoot:SetAttribute(team.Name, self:getTeamScore(team) + 1)
end

function Scrimmage:getTeamScore(team)
    return self.replicatedRoot:GetAttribute(team.Name)
end

function Scrimmage:checkForTie()
	return Promise.delay(2):andThen(function()
        local aliveTeams = {}

        for _, team in self.fightingTeams do
            for _, player in team:GetPlayers() do
                local character = player.Character
                if character == nil then
                    continue
                end

                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid == nil or humanoid.Health <= 0 then
                    continue
                end

                aliveTeams[team] = true
                break
            end
        end

        if count(aliveTeams) == 1 then
            return (next(aliveTeams))
        elseif count(aliveTeams) == 0 then
            return nil
        end
	end)
end

function Scrimmage:loadCharacters(players)
    local promises = {}

    for _, player in players do
        table.insert(promises, Promise.defer(function(resolve)
            player:LoadCharacter()
            resolve(player.Character)
        end))
    end

    return Promise.all(promises)
end

function Scrimmage:putPlayerAway(player, originalCharacter)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Whitelist

	local bin = Bin.new()
    
	local function onCharacterAdded(character)
		local cBin = bin:AddId(Bin.new(), "character")
		local ff = cBin:Add(Instance.new("ForceField"))
		ff.Parent = character

		local cframe, size = self.cage:GetBoundingBox()
        overlapParams.FilterDescendantsInstances = {character}

		cBin:Add(Scrimmage.UpdateEvent:Connect(function()
            local parts = Workspace:GetPartBoundsInBox(cframe, size, overlapParams)

			if parts[1] == nil then
				character:SetPrimaryPartCFrame(self.awayCFrame)
			end
		end))
	end
	
	bin:Add(player.CharacterAdded:Connect(onCharacterAdded))
	if player.Character and player.Character ~= originalCharacter then
		onCharacterAdded(player.Character)
	end
	
	return function()
        bin:DoCleaning()
    end
end

return Scrimmage