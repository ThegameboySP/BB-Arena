local PhysicsService = game:GetService("PhysicsService")

local function spectatorsCantCollide()
	PhysicsService:RegisterCollisionGroup("Spectators")
	PhysicsService:CollisionGroupSetCollidable("Spectators", "Spectators", false)
end

return spectatorsCantCollide
