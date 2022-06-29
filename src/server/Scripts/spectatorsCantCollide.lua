local PhysicsService = game:GetService("PhysicsService")

local function spectatorsCantCollide()
    PhysicsService:CreateCollisionGroup("Spectators")
    PhysicsService:CollisionGroupSetCollidable("Spectators", "Spectators", false)
end

return spectatorsCantCollide