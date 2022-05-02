local Dir = require(script.Parent.Dir)

local Promise = Dir.Promise

local CTF = {
    Name = "CTF";
}

function CTF:OnRegistered()
    self.service:RegisterSystem()
    
end

function CTF:OnInit()
    -- for storing remote events and replicated values and such
    local folder = self.service:GetFolder()
end

return CTF