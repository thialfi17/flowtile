local Hierarchy = {}
local Level = {}

function Level:new()
    local new = {
        regions = {},
    }
    setmetatable(new, self)
    return new
end

function Level:add(region)
    table.insert(self.regions, region)
end

function Level:__index(k)
    return rawget(Level, k)
end

function Hierarchy:new()
    local new = {
        levels = {},
        cur_level = 1,
    }
    table.insert(new.levels, Level:new())
    setmetatable(new, self)
    return new
end

function Hierarchy:next_level()
    self.cur_level = self.cur_level + 1

    if self.levels[self.cur_level] == nil then
        table.insert(self.levels, Level:new())
    end

    return self
end

function Hierarchy:add(region)
    self.levels[#self.levels]:add(region)
    return self
end

function Hierarchy:level_min(level)
    local count = 0

    for region = 1, #self.levels[level].regions do
        count = count + self.levels[level].regions[region].min
    end

    return count
end

function Hierarchy:level_max(level)
    local count = 0

    for region = 1, #self.levels[level].regions do
        count = count + (self.levels[level].regions[region].max or 0)
    end

    return count
end

function Hierarchy:get_min(start)
    local min = 0
    start = start or 1
    for level = start, #self.levels do
        min = min + self:level_min(level)
    end
    return min
end

function Hierarchy:fill_level(sel_level, remaining_windows, config)
    print("filling level: " .. sel_level)
    local win_positions = {}

    local reserved_windows = self:get_min(sel_level + 1)
    local usable_windows = remaining_windows - reserved_windows

    print("usable: " .. usable_windows)
    local level = self.levels[sel_level]

    local regions = require("backend.utils").table.shallow_copy(level.regions)
    local last = false

    while usable_windows > 0 and #regions > 0 do
        local done = {}

        for sel_region = 1, #regions do
            local each = math.ceil(usable_windows / ((#regions - sel_region) + 1))
            local region = regions[sel_region]
            if (region.max ~= nil and each >= region.max) or last then
                local positions = region:populate(each, config)
                usable_windows = usable_windows - #positions

                for i = 1, #positions do
                    win_positions[#win_positions+1] = positions[i]
                end

                table.insert(done, sel_region)
            end
        end

        if #done == 0 then
            last = true
        end

        for i = #done, 1, -1 do
            table.remove(regions, done[i])
        end
    end

    return win_positions
end

function Hierarchy:fill_levels(remaining_windows, config)
    local win_positions = {}

    for level = 1, #self.levels do
        local positions = self:fill_level(level, remaining_windows, config)
        remaining_windows = remaining_windows - #positions

        for i = 1, #positions do
            win_positions[#win_positions+1] = positions[i]
        end
    end

    return win_positions
end

function Hierarchy:__index(k)
    return rawget(Hierarchy, k)
end

return Hierarchy
