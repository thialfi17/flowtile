local M = {

    fill = function(tab, region, count)
        for i = 1, count do
            table.insert(tab, {
                region.x,
                region.y,
                region.width,
                region.height
            })
        end
        return tab
    end,

    rows = function(tab, region, count)
        local height = region.height / count
        for i = 0, count - 1 do
            table.insert(tab, {
                region.x,
                region.y + height*i,
                region.width,
                height
            })
        end
        return tab
    end,

    cols = function(tab, region, count)
        local width = region.width / count
        for i = 0, count - 1 do
            table.insert(tab, {
                region.x + width*i,
                region.y,
                width,
                region.height
            })
        end
        return tab
    end,

    grid = function(tab, region, count)
        local max_col = region.width / 16
        local max_row = region.height / 9
        local factor = 1.0
        local closest_factor = nil
        local rows, cols

        if max_col > max_row then
            factor = max_col / max_row
        else
            factor = max_row / max_col
        end

        for x = 1, (1 + count/2)-1 do
            local y = math.ceil(count / x)
            local cur_factor

            print("X and Y are: " .. x .. ", " .. y)

            if x * y == count + y then goto continue end

            if max_col > max_row then
                cur_factor = x / y
            else
                cur_factor = y / x
            end

            local diff = math.abs(factor - cur_factor)
            if closest_factor == nil or diff < closest_factor then
                if closest_factor ~= nil and (count < (x*y)-y or count < (x*y)-x) then
                    goto continue
                end

                print("Saving X and Y as: " .. x .. ", " .. y)

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
                region.x + (current_row * x_offset),
                region.y + (current_col * y_offset),
                width,
                height,
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
