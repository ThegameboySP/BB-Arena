local PhysicsService = game:GetService("PhysicsService")
PhysicsService:CreateCollisionGroup("Spectators")
PhysicsService:CollisionGroupSetCollidable("Spectators", "Spectators", false)