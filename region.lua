local utils = require('utils')

local defaults = {
    x= 0,
    y= 0,
    width = 0,
    height = 0,
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

function Region:set_layout(sublayout, count)
    self.sublayout = sublayout
    self.count = count
    return self
end

function Region:populate(count, wins)
    local wins = wins or {}
    local sublayouts = require('sublayouts')

    local handled_windows
    if self.count ~= nil and count > self.count then
        handled_windows = self.count
    else
        handled_windows = count
    end
    local remaining = count - handled_windows

    if self.children == nil then
        return remaining, sublayouts[self.sublayout](wins, self, handled_windows)
    end

    -- Not enough windows to flow down into children
    -- TODO: Do I want to rethink how this works?
    if count < #self.children then
        return 0, sublayouts[self.sublayout](wins, self, count)
    end

    -- Distribute remaining windows between children
    local uncapped_children = {}
    for _, child in pairs(self.children) do
        if not child.count then
            -- Queue regions that are uncapped for handling later
            table.insert(uncapped_children, child)
        else
            -- If the region has a window cap populate it first
            count, wins = child:populate(count, wins)
        end
    end

    -- Evenly split remaining windows between remaining regions
    local count_per_child = math.floor(count / #uncapped_children)
    local extra = math.fmod(count, #uncapped_children)

    for i, child in pairs(uncapped_children) do
        if i <= extra then
            -- Fill some regions with extra children when there aren't an
            -- evenly divisible number
            count, wins = child:populate(count_per_child + 1, wins)
        else
            count, wins = child:populate(count_per_child, wins)
        end
    end

    return count, wins
end

function Region:__index(k)
    local raw_v = rawget(self, k)
    -- Return items from this instance if they exist
    if raw_v then return raw_v end

    -- Otherwise special handling to calculate values from parent
    if k == 'x' then
        return (self.parent.width  - self.parent.x) * self.x_ratio + self.parent.x
    elseif k == 'y' then
        return (self.parent.height - self.parent.y) * self.y_ratio + self.parent.y
    elseif k == 'width' then
        return self.parent.width * self.w_ratio
    elseif k == 'height' then
        return self.parent.height * self.h_ratio
    end

    -- Otherwise return item inherited from base class (needed for funcs)
    raw_v = rawget(Region, k)
    return raw_v
end

function Region:print(indent)
    indent = indent or 0
    local pre = string.rep(' ', indent)

    keys = {'x', 'y', 'width', 'height', 'sublayout', 'count'}

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
