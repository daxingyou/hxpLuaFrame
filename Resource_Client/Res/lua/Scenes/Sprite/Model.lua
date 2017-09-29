local Model = {}

function Model:new()
    local new = {}
    self.__index = self
    setmetatable(new,self)

    new.retainCount = 1
    new.lastUseTime = common:getCurTime()
    return new
end

function Model:retain()
    self.retainCount = self.retainCount + 1
    self.lastUseTime = common:getCurTime()
end

function Model:release()
    assert(self.retainCount>=1,"retain count should be larger than 1 when release.")
    self.retainCount = self.retainCount - 1
    self.lastUseTime = common:getCurTime()
end

return Model