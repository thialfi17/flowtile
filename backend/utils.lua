---@class LogLevel
---@field val integer
---@field text string

---@type LogLevel
INFO  = {val = 0, text = "\27[32mINFO"}
---@type LogLevel
WARN  = {val = 1, text = "\27[31mWARNING"}
---@type LogLevel
ERROR = {val = 2, text = "\27[33mERROR"}

---@type LogLevel
local LOG_LEVEL = ERROR

local M = {}

M.weakref = function(o)
    local weak = setmetatable({content=o}, {__mode="v"})
    return function() return weak.content end
end

M.table = {}
M.table.shallow_copy = function(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
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

---@param level LogLevel
---@param message string
M.log = function (level, message)
    if level.val < LOG_LEVEL.val then return end

    local longest = math.max(#INFO.text, #WARN.text, #ERROR.text)
    local pad = string.rep(" ", longest - #level.text)
    print(table.concat({"[", level.text, "\27[0m] ", pad, message}))
end
---@param level LogLevel
M.set_log_level = function (level)
    LOG_LEVEL = level
end

return M
