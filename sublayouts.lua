local M = {

    fill = function(tab, region, count, config)
        local gaps = region.gaps
        for i = 1, count do
            table.insert(tab, {
                region.x + gaps / 2,
                region.y + gaps / 2,
                region.width - gaps,
                region.height - gaps
            })
        end
        return tab
    end,

    rows = function(tab, region, count, config)
        local gaps = region.gaps
        local height = region.height / count
        for i = 0, count - 1 do
            table.insert(tab, {
                region.x + gaps / 2,
                region.y + gaps / 2 + height*i,
                region.width - gaps,
                height - gaps
            })
        end
        return tab
    end,

    cols = function(tab, region, count, config)
        local gaps = region.gaps
        local width = region.width / count
        for i = 0, count - 1 do
            table.insert(tab, {
                region.x + gaps / 2 + width*i,
                region.y + gaps / 2,
                width - gaps,
                region.height - gaps
            })
        end
        return tab
    end,

    grid = function(tab, region, count, config)
        local gaps = region.gaps
        local factor = 16 / 9
        local closest_factor = nil
        local rows, cols

        for x = 1, (1 + count/2) do
            local y = math.ceil(count / x)
            local cur_factor

            if x * y == count + y then goto continue end

            local width = region.width / x
            local height = region.height / y
            cur_factor = width / height

            local diff = math.abs(factor - cur_factor)
            if closest_factor == nil or diff < closest_factor then
                if closest_factor ~= nil and (count < (x*y)-y or count < (x*y)-x) then
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
        for i = 0, count-1 do
            table.insert(tab, {
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

        return tab
    end,
}

return M
