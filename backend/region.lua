local copy = {
    x = 0,
    y = 0,
    width = 0,
    height = 0,
}

---@return number, WinData[] # Returns remaining number of windows and window positioning data.
local fill_from_list = function(list_of_children, remaining_wins, regions, config)
    if regions == 0 then return regions, {} end
    local win_positions = {}
    local fill_with = math.floor(remaining_wins / regions)
    local extra = math.fmod(remaining_wins, regions)

    for _, child in pairs(list_of_children) do
        local target = fill_with
        if extra ~= 0 then
            target = target + 1
            extra = extra - 1
        end

        local positions = child:populate(target, config)

        for p = 1, #positions do
            win_positions[#win_positions+1] = positions[p]
        end

        regions = regions - 1

        -- Handle case where number of generated positions doesn't match
        -- with number requested
        local diff = #positions - target
        if diff ~= 0 then
            remaining_wins = remaining_wins - #positions
            fill_with = math.floor(remaining_wins / regions)
            extra = math.fmod(remaining_wins, regions)
        end

    end

    return regions, win_positions
end

---@class Region
---@field children? Region[]
---@field gaps number # Gap size between windows in pixels (default = `0`)
---@field height? number # Height of the region
---@field last boolean # Indicates if this region should fill after other regions have taken their windows (default = `false`)
---@field max? number # Maximum number of windows this region should take
---@field min? number # Minimum number of windows this region should take before taking any windows
---@field parent? Region
---@field sublayout string # Sublayout used to position the windows of this region
---@field width? number # Width of the region
---@field x? number # X position of the region
---@field y? number # Y position of the region
local Region = {
    sublayout = "fill",
    gaps = 0,
}


---Create a new (empty!) `Region`. Not expected to be used in layouts.
---@return Region
function Region:new()
    local new = {}
    setmetatable(new, self)
    return new
end

---Create a `Region` from the args object given to handle_layout. Typically only used for the top level `Region`.
---@param args LuaArgs
---@return Region
function Region:from_args(args)
    local new = Region:new()

    for k, v in pairs(copy) do
        new[k] = args[k] or v
    end

    return new
end

---Create a region as a sub area of an existing `Region`. Adds the new `Region` as a child to the existing `Region`.
---@param x number X position in pixels
---@param y number Y position in pixels
---@param width number Width in pixels
---@param height number Height in pixels
---@return Region
function Region:from(x, y, width, height)
    local new = Region:new()

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
    table.insert(self.children, new) -- this can be made a weak reference if needed but I'm not sure it is

    return new
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
---@param limits? {[1]: number, [2]: number} # {min, max}
---@return Region # Returns itself.
---@see sublayouts.lua
function Region:set_layout(sublayout, limits)
    self.sublayout = sublayout

    if limits ~= nil then
        self.min = limits[1]
        self.max = limits[2]
    end

    return self
end

---Get the number of windows needed to fill this `Region's` direct child `Regions`.
---@return number Total of all children's minimums
function Region:min_children()
    local min = 0
    if self.children ~= nil then
        for _, child in pairs(self.children) do
            min = min + child.min
        end
    end
    return min
end

---Mark this region to be filled last
---@return Region # Returns itself.
function Region:fill_last()
    self.last = true
    return self
end

---Populate the `Region` with windows. Recursively populates children if there are enough windows to fill them.
---@param requested_windows number # Number of windows left to be positioned.
---@param config Config # Config options for this output/tag/layout.
---@return WinData[] # Returns remaining number of windows and window positioning data.
function Region:populate(requested_windows, config)
    local sublayouts = require('sublayouts')
    local win_positions = {}

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
    if self.children == nil or requested_windows < self:min_children() then
        win_positions = sublayouts[self.sublayout](self, remaining_wins, config)

        -- Number of generated positions could be different from
        -- max number of windows we are meant to support so remove
        -- extras.
        local max = self.max or #win_positions
        local difference = #win_positions - max
        for _ = 1, difference, 1 do
            table.remove(win_positions)
        end

        return win_positions
    end

    -- Distribute remaining windows between children
    remaining_wins = requested_windows
    local fill_last = {}
    local fill_by_count = {}
    local fill_remaining = {}

    local not_last_regions = 0

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
            not_last_regions = not_last_regions + 1
        end
    end

    --local fill_with = 1
    --while total ~= 0 and (fill_with * total < remaining_wins) do
    --    local remove = {}
    --    for i, child in pairs(fill_by_count) do
    --        if fill_with >= child.max then
    --            remaining, win_positions = child:populate(fill_with, config, win_positions)
    --            remaining_wins = remaining_wins - (fill_with - remaining)
    --            total = total - 1
    --            table.insert(remove, 1, i)
    --        end
    --    end
    --    for _, i in pairs(remove) do table.remove(fill_by_count, i) end
    --    fill_with = fill_with + 1
    --end

    -- TODO: Go back to treating fill_by_count as a dict not an array
    local positions = {}

    not_last_regions, positions = fill_from_list(fill_by_count, remaining_wins - #fill_last, not_last_regions, config)
    remaining_wins = remaining_wins - #positions

    win_positions = positions

    not_last_regions, positions = fill_from_list(fill_remaining, remaining_wins - #fill_last, not_last_regions, config)
    remaining_wins = remaining_wins - #positions

    for i = 1, #positions do
        win_positions[#win_positions+1] = positions[i]
    end

    -- Evenly split remaining windows between remaining regions
    _, positions = fill_from_list(fill_last, remaining_wins, #fill_last, config)

    for i = 1, #positions do
        win_positions[#win_positions+1] = positions[i]
    end

    if not self.parent then
        while #win_positions > requested_windows do
            table.remove(win_positions)
        end
    end

    return win_positions
end

function Region:__index(k)
    local dont_inherit = { children = true, parent = true, last = true }
    -- Otherwise special handling to calculate values from parent
    if k == 'min' then
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
