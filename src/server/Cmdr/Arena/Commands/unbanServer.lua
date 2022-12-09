local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local actions = RoduxFeatures.actions
local selectors = RoduxFeatures.selectors

return function(context, userIds)
	local store = context:GetStore("Common").Store
	local root = context:GetStore("Common").Root
	local state = store:getState()

	for _, userId in pairs(userIds) do
		local bannedBy = state.users.banned[userId]

		if bannedBy == nil then
			root:GetFullNameByUserId(userId):andThen(function(name)
				context:Reply(string.format("%s isn't currently banned.", name))
			end)

			continue
		end

		if selectors.getAdmin(state, bannedBy) > selectors.getAdmin(state, context.Executor.UserId) then
			Promise.all({
				root:GetFullNameByUserId(userId),
				root:GetFullNameByUserId(bannedBy),
			}):andThen(function(names)
				context:Reply(
					string.format(
						"%s is banned by %s (%s). You don't have permission to unban them.",
						names[1],
						names[2],
						GameEnum.AdminTiersByValue[selectors.getAdmin(state, bannedBy)] or "unknown"
					)
				)
			end)

			continue
		end

		store:dispatch(actions.setUserBanned(userId, false, context.Executor.UserId))

		root:GetFullNameByUserId(userId):andThen(function(name)
			context:Reply(string.format("Successfully unbanned %s.", name))
		end)
	end

	return ""
end
