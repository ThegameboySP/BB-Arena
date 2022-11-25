local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Root = require(ReplicatedStorage.Common.Root)
local MatterComponents = require(ReplicatedStorage.Common.MatterComponents)
local renderTeams = require(script.Parent.renderTeams)
local removeQueued = require(script.Parent.removeQueued)

return function()
	it("should spawn static teams", function()
		local root, run = Root.newTest({ renderTeams })

		root.state.Teams = Instance.new("Folder")
		Instance.new("Team").Parent = root.state.Teams
		run()

		local team = root.world:get(1, MatterComponents.Team)
		expect(team).to.be.ok()
		expect(team.static).to.equal(true)
	end)

	local function renderTeamCase()
		local root, run = Root.newTest({ renderTeams })

		local teamId = root:GetService("TeamService"):spawnTeam(MatterComponents.Team({
			name = "Test";
			color = BrickColor.Red();
		}))

		local playerMock = { Team = nil }
		root.world:spawn(MatterComponents.Player({
			player = playerMock;
			teamId = teamId;
		}))

		local folder = Instance.new("Folder")
		root.state.Teams = folder

		return root, run, playerMock, folder, teamId
	end

	it("should render a new team and then despawn it", function()
		local root, run, playerMock, folder, teamId = renderTeamCase()
		run()

		local team = folder:FindFirstChild("Test")
		expect(team).to.be.ok()
		expect(team.TeamColor).to.equal(BrickColor.Red())
		expect(playerMock.Team).to.equal(team)

		root.world:despawn(teamId)

		run()
		expect(folder:FindFirstChild("Test")).to.never.be.ok()
		expect(playerMock.Team).to.equal(Teams.Spectators)
	end)

	it("should replace a rendered team", function()
		local root, run, playerMock, folder = renderTeamCase()

		root.world:insert(1, MatterComponents.Team({
			name = "Test2";
			color = BrickColor.Blue();
		}))

		run()

		local team = folder:FindFirstChild("Test2")
		expect(team).to.be.ok()
		expect(#folder:GetChildren()).to.equal(1)
		expect(playerMock.Team).to.equal(team)
	end)

	it("should render Gladiators team and then despawn it", function()
		local root, run = Root.newTest({ renderTeams, removeQueued })

		root.state.mapSupportsGladiators = true
		root.state.gamemodeRequiresGladiators = true

		local folder = Instance.new("Team")
		root.state.Teams = folder

		run()
		expect(folder:FindFirstChild("Gladiators")).to.be.ok()

		root.state.mapSupportsGladiators = false

		run()
		run()
		expect(folder:FindFirstChild("Gladiators")).to.never.be.ok()
	end)
end