local Option = {}

local mt = {
    __index = function(t, k)
        local v = rawget(t, k)
        if v ~= nil then return v end

        if rawget(t, "parent") == nil then return nil end

        return t.parent[k]
    end,
}
setmetatable(Option, mt)

function Option:new(val)
    local o = {}
    setmetatable(o, mt)
    o.parent = Option
    o.value = val
    o.type = type(val)
    return o
end

function Option:type(typ)
    self.type = typ
end

function Option:set(val)
    if type(val) ~= self.type then
        error("Option of type '" .. self.type .. "' was set to invalid type '" .. type(val) .. "' (" .. val .. ")")
    end

    if self.type == "number" then
        if self.min ~= nil and val < self.min then
            self.value = self.min
        elseif self.max ~= nil and val > self.max then
            self.value = self.max
        else
            self.value = val
        end
    else
        self.value = val
    end

    return self
end

function Option:inc(val)
    if self.type ~= "number" then
        return
    end

    self:set(self:get() + val)
end

function Option:get()
    return self.value
end

function Option:limit(min, max)
    self.min = min
    self.max = max
    return self
end

function Option:clone()
    local o = {}
    setmetatable(o, mt)
    o.parent = self
    return o
end

return Option
