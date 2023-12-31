local M = {}

M.weakref = function(o)
    local weak = setmetatable({content=o}, {__mode="v"})
    return function() return weak.content end
end

M.table = {}
M.table.copy = function(t)
    local t2 = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            t2[k] = table.copy(v)
        else
            t2[k] = v
        end
    end
    return t2
end
M.table.print = function(t, indent, nest)
    if not indent then indent = 0 end
    if nest == nil then nest = true end
    local pre = string.rep(' ', indent)
    print('{')
    for k, v in pairs(t) do
        if type(v) == 'table' and nest and nest ~= 0 then
            io.write(pre .. '  ' .. tostring(k) .. " = " )

            if type(nest) == 'number' then
                nest = nest - 1
            end

            M.table.print(v, indent + 2, nest)
        else
            print(pre .. '  ' .. tostring(k) .. ' = ' .. tostring(v) .. ',')
        end
    end
    print(pre .. '},')
end

return M
