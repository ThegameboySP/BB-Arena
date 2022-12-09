local PhysicsService = game:GetService("PhysicsService")

local function playersFlyOnMapTransitionServer()
	PhysicsService:CreateCollisionGroup("Game_NoClip")
	PhysicsService:CollisionGroupSetCollidable("Game_NoClip", "Default", false)
end

return playersFlyOnMapTransitionServer
