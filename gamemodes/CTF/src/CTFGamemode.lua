local Dir = require(script.Parent.Dir)

local Promise = Dir.Promise

local CTF = {
    Name = "CTF";
}

function CTF:OnRegistered()
    self.service:RegisterSystem()
    self.service:RegisterBinder({
        WhitelistedPlayers = {};
    })
end

function CTF:OnInit()
    self.service:Say("")
    self.service:RunPrototypes(workspace)
end

return CTF