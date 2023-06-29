local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Leaderboard = require(ServerScriptService.Server.Services.GameDataStoreService.Leaderboard)

local pages = DataStoreService:GetOrderedDataStore("PlayerKOLeaderboard"):GetSortedAsync(false, 100)
local top100 = pages:GetCurrentPage()

local deserialized = {}
for _, entry in top100 do
	local userId, WOs = Leaderboard.deserializeKey(entry.key)
	table.insert(deserialized, { userId = userId, WOs = WOs, KOs = entry.value })
end

print(HttpService:JSONEncode(deserialized))
