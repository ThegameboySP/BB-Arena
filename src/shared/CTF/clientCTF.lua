local ClientCTF = {}
ClientCTF.__index = ClientCTF

function ClientCTF.new(signals)
    return setmetatable({
        signals = signals;
    }, ClientCTF)
end

function ClientCTF:init()
    self.signals.CTF_EnemyKilledWithFlag:Connect(function()
        playSound(Sounds.KilledEnemy)
    end)
end

function ClientCTF:step(world, components, params)
    for id, flagRecord in world:queryChanged(components.Flag) do
        
    end
end

return ClientCTF