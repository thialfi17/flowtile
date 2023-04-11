local utils = require("utils")
local Option = require('option')

----------------------------------------
--              Defaults              --
----------------------------------------

local defaults = {
    gaps = Option:new(5):limit(0),
    smart_gaps = Option:new(false),

    layout = Option:new("monocle"),

    main_ratio = Option:new(0.65):limit(0.1, 0.9),
    secondary_ratio = Option:new(0.6):limit(0.1, 0.9),
    secondary_count = Option:new(0):limit(0),
}

----------------------------------------
--           Config Layout            --
----------------------------------------

local config = {
    -- TODO: layouts
    layouts = {},

    -- 'outputs' inheritance is simple: if option not set at the bottom level
    -- it searches upwards until it finds it set
    outputs = {
        layouts = {},
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

----------------------------------------
--          Implementation            --
----------------------------------------

--
-- I would strongly recommend not scrolling further... I tried a
-- smarter/prettier solution but got stuck so hard coded all of the
-- inheritance...
--

outputs_mt = {
    __index = function(t, k)
        local v = rawget(t, k)
        if v ~= nil then return v end

        rawset(t, k, defaults[k]:clone())
        return rawget(t, k)
    end
}
setmetatable(config.outputs, outputs_mt)

outputs_tags_mt = {
    __index = function(t, k)
        local v = rawget(t, k)
        if v ~= nil then return v end

        if k == "tags" or k == "tag" then return nil end
        
        rawset(t, k, config.outputs[k]:clone())
        return rawget(t, k)
    end
}
setmetatable(config.outputs.tags, outputs_tags_mt)

outputs_tags_layouts_mt = {
    __index = function(t, k)
        local v = rawget(t, k)
        if v ~= nil then return v end
        
        rawset(t, k, config.outputs.layouts[k]:clone())
        return rawget(t, k)
    end
}
setmetatable(config.outputs.tags.layouts, outputs_tags_layouts_mt)

outputs_tag_mt = {
    __index = function(t, k)
        local v = rawget(t, k)
        if v ~= nil then return v end

        local o = {}
        local o_mt = {
            __index = function(tt, kk)
                local vv = rawget(tt, kk)
                if vv ~= nil then return vv end
                rawset(tt, kk, config.outputs.tags[kk]:clone())
                return rawget(tt, kk)
            end,
        }
        setmetatable(o, o_mt)

        t[k] = o
        return o
    end,
}
setmetatable(config.outputs.tag, outputs_tag_mt)

output_mt = {
    __index = function(t, k)
        local v = rawget(t, k)
        if v ~= nil then return v end

        local o = {}
        local o_mt = {
            __index = function(tt, kk)
                local vv = rawget(tt, kk)
                if vv ~= nil then return vv end

                -- Special handling for 'tags' field of output
                if kk == "tags" then
                    local oo = {}
                    local oo_mt = {
                        __index = function(ttt, kkk)
                            local vvv = rawget(ttt, kkk)
                            if vvv ~= nil then return vvv end

                            -- If specific 'tags' entry doesn't exist see if we
                            -- have an output specific override. If not get the
                            -- option for global outputs
                            vvv = rawget(config.output[k], kkk)
                            if vvv ~= nil then return vvv end
                            rawset(ttt, kkk, config.outputs.tags[kkk]:clone())
                            return rawget(ttt, kkk)
                        end,
                    }
                    setmetatable(oo, oo_mt)
                    tt[kk] = oo
                    return oo
                -- Special handling for 'tag' field of output
                elseif kk == "tag" then
                    local oo = {}
                    local oo_mt = {
                        __index = function(ttt, kkk)
                            local vvv = rawget(ttt, kkk)
                            if vvv ~= nil then return vvv end

                            local ooo = {}
                            local ooo_mt = {
                                __index = function(tttt, kkkk)
                                    local vvvv = rawget(tttt, kkkk)
                                    if vvvv ~= nil then return vvvv end

                                    -- If specific 'tag' entry doesn't exist see if we
                                    -- have a tag specific global override. If not get the
                                    -- default option for this output
                                    vvvv = rawget(config.outputs.tag[kkk], kkkk)
                                    if vvvv ~= nil then return vvvv end
                                    rawset(tttt, kkkk, config.output[k].tags[kkkk]:clone())
                                    return rawget(tttt, kkkk)
                                end,
                            }
                            setmetatable(ooo, ooo_mt)
                            ttt[kkk] = ooo
                            return ooo
                        end,
                    }
                    setmetatable(oo, oo_mt)
                    tt[kk] = oo
                    return oo
                end
                
                rawset(tt, kk, config.outputs[kk]:clone())
                return rawget(tt, kk)
            end,
        }
        setmetatable(o, o_mt)

        t[k] = o
        return o
    end,
}
setmetatable(config.output, output_mt)

return config
