local reconcileTeams = require(script.parent.reconcileTeams)

local function count(map)
	local n = 0
	for _ in map do
		n += 1
	end

	return n
end

return function()
	it("should reconcile when newTeams > oldTeams, splitting apart old teams", function()
		local players = { {}, {} }
		local reconciledTeams, newTeamMap, untrackedPlayers = reconcileTeams(
			players,
			{ Red = BrickColor.Red(), Blue = BrickColor.Blue() },
			{
				Gladiators = { players = { players[1], players[2] }, color = BrickColor.Red() },
			}
		)

		expect(count(reconciledTeams)).to.equal(1)

		local _, newTeam = next(reconciledTeams)
		expect(newTeam == newTeamMap.Red or newTeam == newTeamMap.Blue).to.equal(true)

		expect(#newTeamMap.Blue.players).to.equal(1)
		expect(#newTeamMap.Red.players).to.equal(1)
		expect(newTeamMap.Red.players[1]).never.to.equal(newTeamMap.Blue.players[1])
		expect(#untrackedPlayers).to.equal(0)
	end)

	it("should reconcile when oldTeams > newTeams, merging old teams together", function()
		local players = { {}, {} }
		local reconciledTeams, newTeamMap, untrackedPlayers = reconcileTeams(
			players,
			{ Gladiators = BrickColor.Red() },
			{
				Red = { color = BrickColor.Red(), players = { players[1] } },
				Blue = { color = BrickColor.Blue(), players = { players[2] } },
			}
		)

		expect(count(reconciledTeams)).to.equal(1)

		expect(#newTeamMap.Gladiators.players).to.equal(2)
		expect(newTeamMap.Gladiators.players[1]).never.to.equal(newTeamMap.Gladiators.players[2])
		expect(#untrackedPlayers).to.equal(0)
	end)

	it("should just return untracked players when no new teams are given", function()
		local _, _, untrackedPlayers = reconcileTeams({ {}, {} }, {}, { Gladiators = BrickColor.Red() })

		expect(#untrackedPlayers).to.equal(2)
		expect(untrackedPlayers[1]).never.to.equal(untrackedPlayers[2])
	end)

	it("should reconcile when oldTeams == newTeams, transferring each player", function()
		local players = { {}, {} }
		local reconciledTeams, newTeamMap, untrackedPlayers = reconcileTeams(players, {
			Red = { color = BrickColor.Red(), players = { players[1] } },
			Blue = { color = BrickColor.Blue(), players = { players[2] } },
		}, {
			Black = { color = BrickColor.Black(), players = { players[1] } },
			White = { color = BrickColor.White(), players = { players[2] } },
		})

		expect(count(reconciledTeams)).to.equal(2)

		local key, newTeam = next(reconciledTeams)
		expect(newTeam == newTeamMap.Red or newTeam == newTeamMap.Blue).to.equal(true)
		local _, newTeam2 = next(reconciledTeams, key)
		expect(newTeam2 == newTeamMap.Red or newTeam2 == newTeamMap.Blue).to.equal(true)

		expect(#newTeamMap.Red.players).to.equal(1)
		expect(#newTeamMap.Blue.players).to.equal(1)
		expect(newTeamMap.Red.players[1]).never.to.equal(newTeamMap.Blue.players[1])
		expect(#untrackedPlayers).to.equal(0)
	end)
end
