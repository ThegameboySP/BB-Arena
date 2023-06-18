local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local Leaderboard = require(ReplicatedStorage.ClientModules.UI.Leaderboard)

local function mountLeaderboards(root)
	local store
	-- Hoarcekat compatibility
	if root.changed then
		store = root
	else
		store = root.Store
	end

	local mounts = {}
	for _, leaderboard in CollectionService:GetTagged("LeaderboardSign") do
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surfaceGui.PixelsPerStud = 20
		surfaceGui.Brightness = 1.5
		surfaceGui.Parent = leaderboard

		local roactTree = Roact.createElement(Leaderboard)
		roactTree = Roact.createElement(RoactRodux.StoreProvider, {
			store = store,
		}, {
			Main = roactTree,
		})

		table.insert(mounts, {
			gui = surfaceGui,
			tree = Roact.mount(roactTree, surfaceGui),
		})
	end

	return function()
		for _, mount in mounts do
			mount.gui.Parent = nil
			Roact.unmount(mount.tree)
		end
	end
end

return mountLeaderboards
