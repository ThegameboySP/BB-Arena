local PhysicsService = game:GetService("PhysicsService")

local function playersFlyOnMapTransitionServer()
	PhysicsService:RegisterCollisionGroup("Game_NoClip")
	PhysicsService:CollisionGroupSetCollidable("Game_NoClip", "Default", false)
end

return playersFlyOnMapTransitionServer
