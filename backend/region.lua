local Hierarchy = require("backend.hierarchy")

---@class Region
---@field children? Region[]
---@field gaps number # Gap size between windows in pixels (default = `0`)
---@field height? number # Height of the region
---@field hierarchy Hierarchy
---@field last boolean # Indicates if this region should fill after other regions have taken their windows (default = `false`)
---@field max? number # Maximum number of windows this region should take
---@field min? number # Minimum number of windows this region should take before taking any windows
---@field name string # Region name - used for debugging
---@field parent? Region
---@field sublayout string # Sublayout used to position the windows of this region
---@field width? number # Width of the region
---@field x? number # X position of the region
---@field y? number # Y position of the region
local Region = { }


---Create a new (empty!) `Region`. Not expected to be used in layouts.
---@protected
---@param name string Region name - used for debugging
---@return Region
function Region:new(name)
    local new = {
        name = name,
        hierarchy = Hierarchy:new(),
    }
    setmetatable(new, self)
    return new
end

---Create a `Region` from the args object given to handle_layout. Typically only used for the top level `Region`.
---@param name string Region name - used for debugging
---@param args LuaArgs
---@return Region
function Region:from_args(name, args)
    local new = Region:new(name)

    new.x = 0
    new.y = 0
    new.width = args.width
    new.height = args.height

    return new
end

---Create a region as a sub area of an existing `Region`.
---Adds the new `Region` as member of the current `Hierarchy` tier.
---@param name string Region name
---@param x number X position in pixels
---@param y number Y position in pixels
---@param width number Width in pixels
---@param height number Height in pixels
---@return Region
function Region:from(name, x, y, width, height)
    local new = Region:new(name)

    if x + width > self.width then
        print("Sub-region X ends outside of bounds!")
    end
    if y + height > self.height then
        print("Sub-region Y ends outside of bounds!")
    end

    new.x = self.x + x
    new.y = self.y + y
    new.width = width
    new.height = height
    new.parent = self

    self.children = self.children or {}
    table.insert(self.children, new)

    -- Add to parent's hierarchy
    self.hierarchy:add(new)

    return new
end

---Move the internal `Hierarchy` to the next tier
---@return self
function Region:next_tier()
    self.hierarchy:next_level()
    return self
end

---Set the size of gaps between windows in the `Region` and moves/resizes the `Region` to introduce gaps between different regions.
---@param gaps number # Size of gaps in pixels.
---@return Region # Returns itself.
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

---Set the sublayout of the `Region` and any relevant window limits.
---
---@param sublayout string # Sub-layout as found in the `sublayouts` module.
---@param limits {[1]: number, [2]: number} # {min, max}
---@return Region # Returns itself.
---@see sublayouts.lua
function Region:set_layout(sublayout, limits)
    self.sublayout = sublayout

    if limits ~= nil then
        self.min = limits[1] or 0
        self.max = limits[2]

        if self.max and self.min > self.max then
            self.max = self.min
        end
    end

    return self
end

---Populate the `Region` with windows. Recursively populates children if there are enough windows to fill them.
---@param requested_windows number # Number of windows left to be positioned.
---@param config Config # Config options for this output/tag/layout.
---@return WinData[] # Returns remaining number of windows and window positioning data.
function Region:populate(requested_windows, config)
    local sublayouts = require('sublayouts')
    local win_positions = {}

    local u = require("backend.utils")
    u.log(DEBUG, table.concat({"populating region: ", self.name, " (r: ", requested_windows, ", region: ", tostring(self), ")"}))

    local remaining_wins
    if self.max ~= nil and requested_windows > self.max then
        remaining_wins = self.max
    else
        remaining_wins = requested_windows
    end

    -- If this region doesn't have children and is just a sublayout
    -- then generate the positioning information
    --   OR
    -- Not enough windows to flow down into children so fallback
    -- to default layout for this region
    if self.children == nil or requested_windows < self.hierarchy:get_min() then
        win_positions = sublayouts[self.sublayout](self, remaining_wins, config)

        -- Number of generated positions could be different from
        -- max number of windows we are meant to support so remove
        -- extras.
        local max = self.max or #win_positions
        local difference = #win_positions - max
        for _ = 1, difference, 1 do
            table.remove(win_positions)
        end

        if not self.parent then
            while #win_positions > requested_windows do
                table.remove(win_positions)
            end
        end

        return win_positions
    end

    -- Distribute remaining windows between children
    remaining_wins = requested_windows

    win_positions = self.hierarchy:fill_levels(remaining_wins, config)

    if not self.parent then
        while #win_positions > requested_windows do
            table.remove(win_positions)
        end
    end

    return win_positions
end

---Only called when the index doesn't exist. Used to inherit the following
---options from a parent:
--- - gaps
---
---@private
---@return any
function Region:__index(index)
    local inherit = {
        gaps = true,
    }

    if Region[index] == nil and inherit[index] == nil then
        return nil
    end

    -- Otherwise return item inherited from base class (needed for funcs)
    if rawget(self, "parent") then
        return rawget(self, "parent")[index]
    else
        return Region[index]
    end
end

---Print useful keys from the region
function Region:print(indent)
    indent = indent or 0
    local pre = string.rep(' ', indent)

    keys = {'x', 'y', 'width', 'height', 'sublayout', 'min', 'max', 'hierarchy', 'last'}

    print('Region (' .. tostring(self) .. ') {')

    for _, v in pairs(keys) do
        print(pre .. '  ' .. v .. ' = ' .. tostring(self[v]) .. ',')
    end
    if self.parent then
        print(pre .. '  parent = ' .. tostring(self.parent) .. ',')
    end
    if self.children then
        print(pre .. '  children = {')
        for k, v in pairs(self.children) do
            io.write(pre .. '    ' .. k .. ' = ')
            v:print(indent+4)
        end
        print(pre .. '  },')
    end
    print(pre .. '}')
end

return Region
