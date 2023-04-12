local utils = require("utils")
local Option = require('option')

----------------------------------------
--              Defaults              --
----------------------------------------

local defaults = {
    default = Option:new("test"),
    --gaps = Option:new(5):limit(0),
    --smart_gaps = Option:new(false),

    --layout = Option:new("monocle"),

    --main_ratio = Option:new(0.65):limit(0.1, 0.9),
    --secondary_ratio = Option:new(0.6):limit(0.1, 0.9),
    --secondary_count = Option:new(0):limit(0),
}

----------------------------------------
--           Config Layout            --
----------------------------------------

--[[
local config = {
    -- 'outputs' inheritance is simple: if option not set at the bottom level
    -- it searches upwards until it finds it set
    outputs = {
        tags = {
            layouts = {},
        },
        tag = {},
    },
    -- 'output' inheritance is complicated: if option is not set then try and
    -- look for most specific option. E.g. if output['HDMI-A-1'].tags.layout =
    -- 'grid' and outputs.tag[1].layout = 'monocle' then monocle layout will
    -- get applied. Order of inheritance may need reconsidering
    output = {},
}
--]]

local config = {}

----------------------------------------
--          Implementation            --
----------------------------------------

-- This is a table which directly inherits its keys from one or more tables. It prioritizes the ACTUAL keys from the earliest table and then will get the inherited key from the last table.
local GroupTable = {}
local _GroupTable = {}
setmetatable(GroupTable, GroupTable)

function GroupTable.__index(t, k)
    local v

    if _GroupTable[t] == nil then return nil end

    local last = nil
    for i, p in ipairs(_GroupTable[t]) do
        last = rawget(p, k)
        if last ~= nil then
            rawset(t, k, last:clone())
            return rawget(t, k)
        else
            last = p[k]
        end
    end

    return last
end

function GroupTable.new(parents)
    local o = {}
    setmetatable(o, GroupTable)
    _GroupTable[o] = parents
    return o
end

-- This is a table which is designed to inherit from TWO sources. It inherits from a general table e.g. outputs/tags and also a specific table e.g. output[1]. It will take the actual result from the generic table first and then actual or inherited results from the specific table after
local MixedTable = {}
local _MixedTable = {}
setmetatable(MixedTable, MixedTable)

function MixedTable.__index(t, k)
    local v

    -- Needs to be a group table with the first inheritor being the tags from the outputs and the second being the individual table from the tag in outputs

    v = GroupTable.new({_MixedTable[t][1], _MixedTable[t][2][k]})

    rawset(t, k, v)
    return rawget(t, k)
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
    local v
    v = GroupTable.new(_IndividualTable[t])
    rawset(t, k, v)

    for _, t2 in ipairs(_IndividualTable[t]) do
        local plurals = {}
        for key, val in pairs(t2) do
            if _GroupTable[val] ~= nil then
                rawset(v, key, GroupTable.new({val}))
            elseif _IndividualTable[val] ~= nil then
                table.insert(plurals, {key, val})
            end
        end
        for _, tab in ipairs(plurals) do
            rawset(v, tab[1], MixedTable.new({rawget(v, tab[1] .. "s"), tab[2]}))
        end
    end

    return rawget(t, k)
end

function IndividualTable.new(parents)
    local o = {}
    setmetatable(o, IndividualTable)
    _IndividualTable[o] = parents
    return o
end

config.outputs = {}
config.outputs.tags = GroupTable.new({defaults})
config.outputs.tags.layouts = GroupTable.new({{}})
config.outputs.tag = IndividualTable.new({config.outputs.tags})

config.output = IndividualTable.new({config.outputs})

return config
