local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Llama = require(ReplicatedStorage.Packages.Llama)
local makeEnum = require(ReplicatedStorage.Common.Utils.makeEnum)

local Dictionary = Llama.Dictionary
local AdminTiers = require(script.Parent.AdminTiers)

return makeEnum("AdminTiersByValue", Dictionary.flip(AdminTiers))
