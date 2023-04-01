local M = {
    fill = function(tab, region, count)
        for i = 1, count do
            table.insert(tab, {region.x, region.y, region.width, region.height})
        end
        return tab
    end,
    rows = function(tab, region, count)
        local height = region.height / count
        for i = 0, count - 1 do
            table.insert(tab, {region.x, region.y + height*i, region.width, height})
        end
        return tab
    end,
}

return M
