local utils = require('utils')

local defaults = {
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    gaps = 0,
}

local Region = {
    sublayout = "fill",
}

-- Create a new (empty!) region object
function Region:new()
    local new = {}
    setmetatable(new, self)
    --self.__index = self
    return new
end

-- Create a region from the args object given to handle_layout
function Region:from_args(args)
    local new = Region:new()

    for k, v in pairs(defaults) do
        new[k] = args[k] or v
    end

    return new
end

-- Create a region as a sub area of an existing region
function Region:from(x_ratio, y_ratio, w_ratio, h_ratio)
    local new = Region:new()

    new.x_ratio = x_ratio
    new.y_ratio = y_ratio
    new.w_ratio = w_ratio
    new.h_ratio = h_ratio
    new.parent = self

    self.children = self.children or {}
    table.insert(self.children, new) -- this can be made a weak reference if needed but I'm not sure it is

    return new
end

function Region:set_gaps(gaps)
    self.gaps = gaps

    if self.x ~= nil then
        self.x = self.x + gaps / 2
        self.y = self.y + gaps / 2
        self.width = self.width - gaps
        self.height = self.height - gaps
    end

    return self
end

function Region:set_layout(sublayout, limits)
    self.sublayout = sublayout

    if limits ~= nil then
        self.min = limits[1]
        self.max = limits[2]
    end

    return self
end

function Region:min_children()
    local min = 0
    if self.children ~= nil then
        for _, child in pairs(self.children) do
            min = min + child.min
        end
    end
    return min
end

function Region:fill_last()
    self.last = true
    return self
end

function Region:populate(count, config, wins)
    local wins = wins or {}
    local sublayouts = require('sublayouts')

    local handled_windows
    if self.max ~= nil and count > self.max then
        handled_windows = self.max
    else
        handled_windows = count
    end
    local remaining = count - handled_windows

    if self.children == nil then
        return remaining, sublayouts[self.sublayout](wins, self, handled_windows, config)
    end

    -- Not enough windows to flow down into children
    if count < self:min_children() then
        return remaining, sublayouts[self.sublayout](wins, self, count, config)
    end

    -- Distribute remaining windows between children
    local fill_last = {}
    local fill_by_count = {}
    local fill_remaining = {}

    local total = 0

    for _, child in pairs(self.children) do
        if child.last == true then
            table.insert(fill_last, child)
        else
            if child.max ~= nil and child.max ~= 0 then
                table.insert(fill_by_count, child)
            end
            if child.max == nil then
                table.insert(fill_remaining, child)
            end
            total = total + 1
        end
    end

    local fill_from_list = function(tab, total)
        if total == 0 then return total end
        local fill_with = math.floor(count / total)
        local extra = math.fmod(count, total)

        for i, child in pairs(tab) do
            if i <= extra then
                remaining, wins = child:populate(fill_with + 1, config, wins)
                count = count - (fill_with + 1 - remaining)
            else
                remaining, wins = child:populate(fill_with, config, wins)
                count = count - (fill_with - remaining)
            end
            total = total - 1
        end

        return total
    end

    count = count - #fill_last

    local fill_with = 1
    while total ~= 0 and (fill_with * total < count) do
        local remove = {}
        for i, child in pairs(fill_by_count) do
            if fill_with >= child.max then
                remaining, wins = child:populate(fill_with, config, wins)
                count = count - (fill_with - remaining)
                total = total - 1
                table.insert(remove, 1, i)
            end
        end
        for _, i in pairs(remove) do table.remove(fill_by_count, i) end
        fill_with = fill_with + 1
    end

    -- TODO: Go back to treating fill_by_count as a dict not an array
    total = fill_from_list(fill_by_count, total)
    total = fill_from_list(fill_remaining, total)

    count = count + #fill_last

    -- Evenly split remaining windows between remaining regions
    fill_from_list(fill_last, #fill_last)

    return count, wins
end

function Region:__index(k)
    local dont_inherit = { children = true, parent = true, last = true }
    -- Otherwise special handling to calculate values from parent
    if k == 'x' then
        return math.floor(self.parent.width * self.x_ratio) + self.parent.x
    elseif k == 'y' then
        return math.floor(self.parent.height * self.y_ratio) + self.parent.y
    elseif k == 'width' then
        return math.floor(self.parent.width * self.w_ratio)
    elseif k == 'height' then
        return math.floor(self.parent.height * self.h_ratio)
    elseif k == 'min' then
        local min = self:min_children()
        if min == 0 then
            return 1
        else
            return min
        end
    elseif dont_inherit[k] then
        return nil
    end

    -- Otherwise return item inherited from base class (needed for funcs)
    if rawget(self, "parent") then
        return rawget(self, "parent")[k]
    else
        return rawget(Region, k)
    end
end

function Region:print(indent)
    indent = indent or 0
    local pre = string.rep(' ', indent)

    keys = {'x', 'y', 'width', 'height', 'sublayout', 'min', 'max', 'last'}

    print('Region (' .. tostring(self) .. ') {')

    for k, v in pairs(keys) do
        print(pre .. '  ' .. v .. ' = ' .. tostring(self[v]) .. ',')
    end
    if self.parent then
        print(pre .. '  parent = ' .. tostring(self.parent) .. ',')
    end
    if self.children then
        print(pre .. '  children = {')
        for k, v in pairs(self.children) do
            io.write(pre .. '    ' .. k .. ' = ')
            v:print(4)
        end
        print(pre .. '  },')
    end
    print(pre .. '}')
end

return Region
