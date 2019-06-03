local Rabbitcage = Class(function(self, inst)
    self.inst = inst
    
    self.onputrabbit = nil
    self.ondeadrabbit = nil
    
    self.hasrabbit = false
end)

function Rabbitcage:HasRabbit()
    return self.hasrabbit
end


function Rabbitcage:PutRabbit()
    self.hasrabbit = true
end

function Rabbitcage:RemoveRabbit()
    self.hasrabbit = false
end

function Rabbitcage:GetDebugString()
    return string.format("hasrabbit: %s", tostring(self.hasrabbit))
end


return Rabbitcage
