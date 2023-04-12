local utils = require("utils")

----------------------------------------
--           Config Layout            --
----------------------------------------

local config = {}

----------------------------------------
--          Implementation            --
----------------------------------------

-- This is a table which directly inherits its keys from one or more tables. It prioritizes the ACTUAL keys from the earliest table and then will get the inherited key from the last table.

OptionGroup = {}
_Option_vals = {}
_Option_meta = {}
_Option_hier = {}

local function get_parent_meta(opt, key)
    local last_parent = nil
    local parents = _Option_hier[opt]

    if parents == nil then
        return nil
    end

    for _, parent in ipairs(parents) do
        local meta = _Option_meta[parent][key]
        if meta ~= nil then
            return meta
        end
        last_parent = parent
    end

    return get_parent_meta(last_parent, key)
end

function OptionGroup:new(parents)
    local o = {}
    setmetatable(o, self)
    _Option_vals[o] = {}
    _Option_meta[o] = {}
    _Option_hier[o] = parents
    return o
end

function OptionGroup.__index(t, k)
    --print("Accessing: " .. tostring(k))
    if OptionGroup[k] ~= nil then return OptionGroup[k] end

    if _Option_vals[t][k] ~= nil then
        return _Option_vals[t][k]
    elseif _Option_hier[t] ~= nil then
        local last = nil
        for i, parent in ipairs(_Option_hier[t]) do
            --local v = parent[k] -- This will continue to inherit which we need to be able to block
            local v = _Option_vals[parent][k] -- rawget equivalent
            if v ~= nil then
                return v
            end
            last = parent[k]
            --print(last)
        end
        return last
    end
    return nil
end

function validate(meta, v)
    if type(v) ~= meta.type then
        print("Incorrect type! Ignoring...")
        return nil
    end
    if meta.type == "number" then
        if meta.min ~= nil and v < meta.min then
            return meta.min
        elseif meta.max ~= nil and v > meta.max then
            return meta.max
        else
            return v
        end
    end
    return v
end

function OptionGroup.__newindex(t, k, v)
    --print("Setting: " .. tostring(k) .. " to " .. tostring(v))
    local meta = _Option_meta[t][k]

    if meta ~= nil then
        v = validate(meta, v)

        if v == nil then
            return
        end

    elseif _Option_hier[t] ~= nil then
        meta = get_parent_meta(t, k)

        if meta ~= nil then
            v = validate(meta, v)

            if v == nil then
                return
            end
        end
    end
    _Option_meta[t][k] = meta or {type = type(v)}
    _Option_vals[t][k] = v
end

function OptionGroup:print()
    require("utils").table.print(_Option_vals[self])
end

function OptionGroup:iter()
    return next, _Option_vals[self], nil
end

function OptionGroup:limit(var, min, max)
    local meta = _Option_meta[self][var]
    if meta ~= nil then
        meta.min = min
        meta.max = max
    else
        _Option_meta[self][var] = {
            min = min,
            max = max,
            type = "number",
        }
    end
end

-- This is a table which is designed to inherit from TWO sources. It inherits from a general table e.g. outputs/tags and also a specific table e.g. output[1]. It will take the actual result from the generic table first and then actual or inherited results from the specific table after
local MixedTable = {}
local _MixedTable = {}
setmetatable(MixedTable, MixedTable)

function MixedTable.__index(t, k)
    local v = OptionGroup:new({_MixedTable[t][1], _MixedTable[t][2][k]})

    t[k] = v
    return t[k]
end

function MixedTable.new(parents)
    local o = {}
    setmetatable(o, MixedTable)
    _MixedTable[o] = parents
    return o
end

-- This table generates individual tables for specific tags/outputs from the generic tables. It will also setup inheritance for any children that have both specific and generic versions as well since their layout cannot be determined
local IndividualTable = {}
local _IndividualTable = {}
setmetatable(IndividualTable, IndividualTable)

function IndividualTable.__index(t, k)
    local v = OptionGroup:new(_IndividualTable[t])
    t[k] = v

    for _, t2 in ipairs(_IndividualTable[t]) do
        local plurals = {}
        for key, val in t2:iter() do
            --print("KEY: " .. key)
            if _Option_vals[val] ~= nil then
                --print("TAGS: " .. key)
                v[key] = OptionGroup:new({val})
            elseif _IndividualTable[val] ~= nil then
                --print("TAG: " .. key)
                table.insert(plurals, {key, val})
            end
        end
        for _, tab in ipairs(plurals) do
            v[tab[1]] = MixedTable.new({v[tab[1] .. "s"], tab[2]})
        end
    end

    return t[k]
end

function IndividualTable.new(parents)
    local o = {}
    setmetatable(o, IndividualTable)
    _IndividualTable[o] = parents
    return o
end

config.outputs = OptionGroup:new()
config.outputs.tags = OptionGroup:new({config.outputs})
config.outputs.tags.layouts = OptionGroup:new()
config.outputs.tag = IndividualTable.new({config.outputs.tags})

config.output = IndividualTable.new({config.outputs})

return config
