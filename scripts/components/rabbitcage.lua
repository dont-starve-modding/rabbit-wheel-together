local Rabbitcage = Class(function(self, inst)
    self.inst = inst
    
    self.onputrabbit = nil
    self.ondeadrabbit = nil
    
    self.hasrabbit = false
end)

function Rabbitcage:HasRabbit()
    return self.hasrabbit
end


function Rabbitcage:TakeRabbit(rabbit, doer)
    self.hasrabbit = true

    if self.ontakerabbit then
        self.onputrabbit(self.inst, rabbit)
    end

    return true
    -- else return false
end

function Rabbitcage:GetDebugString()
    return string.format("hasrabbit: %s", tostring(self.hasrabbit))
end


return Rabbitcage
