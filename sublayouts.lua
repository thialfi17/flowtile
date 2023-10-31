---@module 'region'
---@module 'layout'
---@module 'config'

---@alias SubLayout fun(region: Region, count: number, config: Config): WinData[]

local M = {}

---@type SubLayout
---Puts each window maximised on top of each other in the `Region`.
M.fill = function(region, count, _)
    local gaps = region.gaps
    local positions = {}
    for _ = 1, count do
        table.insert(positions, {
            region.x + gaps / 2,
            region.y + gaps / 2,
            region.width - gaps,
            region.height - gaps
        })
    end
    return positions
end

---@type SubLayout
---Puts each window on top of each other but slightly offset to make it possible to see there are multiple windows. Maximum offset is configurable with `config.max_offset`.
M.stack = function(region, count, config)
    local positions = {}
    local gaps = region.gaps
    local max_offset = config.max_offset
    local offset_per = math.floor(max_offset / count)
    for i = 0, count - 1 do
        table.insert(positions, {
            region.x + (gaps / 2) + (offset_per * i),
            region.y + (gaps / 2) + (offset_per * i),
            region.width - gaps - offset_per * ((count - 1)),
            region.height - gaps - offset_per * ((count - 1))
        })
    end
    return positions
end

---@type SubLayout
---Places windows stacked one above another without overlapping.
M.rows = function(region, count, _)
    local positions = {}
    local gaps = region.gaps
    local remaining_height = region.height
    local done_height = 0
    for i = 0, count - 1 do
        local height = math.ceil(remaining_height / (count - i))
        table.insert(positions, {
            region.x + gaps / 2,
            region.y + gaps / 2 + done_height,
            region.width - gaps,
            height - gaps
        })

        remaining_height = remaining_height - height
        done_height = done_height + height
    end
    return positions
end

---@type SubLayout
---Places windows side-by-side without overlapping.
M.cols = function(region, count, _)
    local positions = {}
    local gaps = region.gaps
    local remaining_width = region.width
    local done_width = 0
    for i = 0, count - 1 do
        local width = math.ceil(remaining_width / (count - i))
        table.insert(positions, {
            region.x + gaps / 2 + done_width,
            region.y + gaps / 2,
            width - gaps,
            region.height - gaps
        })

        remaining_width = remaining_width - width
        done_width = done_width + width
    end
    return positions
end

---@type SubLayout
---Places windows in a grid. Resizes the grid depending on the number of windows
---and the target aspect ratio of the grid cells. Target aspect ratio is configured
---with `config.grid_ratio`.
---
---Can return more positions than the count given.
-- TODO: would be nice if it would automatically fill empty space
M.grid = function(region, count, config)
    if count == 0 then return {} end

    local gaps = region.gaps
    local factor = config.grid_ratio
    local closest_factor = nil
    local rows, cols
    local positions = {}

    for x = 1, (1 + count / 2) do
        local y = math.ceil(count / x)
        local cur_factor

        if x * y == count + y then goto continue end

        local width = region.width / x
        local height = region.height / y
        cur_factor = width / height

        local diff = math.abs(factor - cur_factor)
        if closest_factor == nil or diff < closest_factor then
            if closest_factor ~= nil and (count < (x * y) - y or count < (x * y) - x) then
                goto continue
            end

            cols = x
            rows = y
            closest_factor = diff
            if cur_factor == factor then break end
        end

        ::continue::
    end

    local width = (region.width / cols)
    local height = (region.height / rows)
    local x_offset = width
    local y_offset = height

    local current_col = 0
    local current_row = 0

    -- Make a position for each cell in grid even if it might not be filled.
    -- It is left up to the regions to remove extra positions.
    for _ = 1, cols * rows do
        table.insert(positions, {
            region.x + gaps / 2 + (current_row * x_offset),
            region.y + gaps / 2 + (current_col * y_offset),
            width - gaps,
            height - gaps,
        })

        if current_col < rows - 1 then
            current_col = current_col + 1
        else
            current_col = 0
            current_row = current_row + 1
        end
    end

    return positions
end

return M
