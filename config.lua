local config = {}

config.settings = {}
config.restrict = {}


config.lim = function(var, val, min, max)

    if config.restrict[var] then
        local restrict = config.restrict[var]
        if type(val) ~= restrict.type then
            print("Incompatible type for setting " .. var .. "(" .. type(val) .. " ~= " .. restrict.type .. ")")
            return false, nil
        end

        if type(val) == "number" then
            if restrict.min and val < restrict.min then
                val = restrict.min
            end
            if restrict.max and val > restrict.max then
                val = restrict.max
            end
            return true, val
        end
        return true, val
    else
        config.restrict[var] = {
            type = type(val),
            min = min,
            max = max,
        }
        return true, val
    end

end

config.set = function(args, lim)
    local sel_out = args[1]
    local sel_tag = args[2]
    local sel_lay = args[3]
    local var = args[4]
    local val = args[5]

    local min, max
    if lim then
        min = lim[1]
        max = lim[2]
    end

    if var == nil or type(var) ~= "string" then
        error("Invalid variable name!")
    end

    pass, val = config.lim(var, val, min, max)

    if not pass then return end

    if sel_out == nil then sel_out = "all" end
    if sel_tag == nil then sel_tag = "all" end
    if sel_lay == nil then sel_lay = "all" end

    if (config.settings.all == nil or config.settings.all.all == nil or config.settings.all.all.all[var] == nil) and (sel_out ~= "all" or sel_tag ~= "all" or sel_lay ~= "all") then
        local output = config.settings["all"]
        if not output then
            output = {}
            config.settings["all"] = output
        end

        local tag = output["all"]
        if not tag then
            tag = {}
            output["all"] = tag
        end

        local layout = tag["all"]
        if not layout then
            layout = {}
            tag["all"] = layout
        end

        layout[var] = val
    end

    local output = config.settings[sel_out]
    if not output then
        output = {}
        config.settings[sel_out] = output
    end

    local tag = output[sel_tag]
    if not tag then
        tag = {}
        output[sel_tag] = tag
    end

    local layout = tag[sel_lay]
    if not layout then
        layout = {}
        tag[sel_lay] = layout
    end

    layout[var] = val
end

config.inc = function(args)
    local val = config.get(args)

    args[5] = args[5] + val

    config.set(args)
end

config.get = function(args)
    local sel_out = args[1]
    local sel_tag = args[2]
    local sel_lay = args[3]
    local var = args[4]

    if sel_out == nil then sel_out = "all" end
    if sel_tag == nil then sel_tag = "all" end
    if sel_lay == nil then sel_lay = "all" end

    if not config.settings[sel_out] then
        config.settings[sel_out] = {}
    end

    if not config.settings[sel_out][sel_tag] then
        config.settings[sel_out][sel_tag] = {}
    end

    if not config.settings[sel_out][sel_tag][sel_lay] then
        config.settings[sel_out][sel_tag][sel_lay] = {}
    end

    local value = config.settings[sel_out][sel_tag][sel_lay][var]
    if value ~= nil then
        return value
    end

    if sel_lay ~= "all" then
        if config.settings[sel_out][sel_tag]["all"] ~= nil then
            if config.settings[sel_out][sel_tag]["all"][var] ~= nil then
                return config.settings[sel_out][sel_tag]["all"][var]
            end
        end
    end

    if sel_tag ~= "all" then
        if config.settings[sel_out]["all"] ~= nil then
            if config.settings[sel_out]["all"][sel_lay] ~= nil then
                if config.settings[sel_out]["all"][sel_lay][var] ~= nil then
                    return config.settings[sel_out]["all"][sel_lay][var]
                end
            end

            if sel_lay ~= "all" then
                if config.settings[sel_out]["all"]["all"] ~= nil then
                    if config.settings[sel_out]["all"]["all"][var] ~= nil then
                        return config.settings[sel_out]["all"]["all"][var]
                    end
                end
            end
        end
    end

    if sel_out ~= "all" then
        if config.settings["all"] ~= nil then
            if config.settings["all"][sel_tag] ~= nil then
                if config.settings["all"][sel_tag][sel_lay] ~= nil then
                    return config.settings["all"][sel_tag][sel_lay][var]
                end
            end


            if sel_tag ~= "all" then
                if config.settings["all"]["all"] ~= nil then
                    if config.settings["all"]["all"][sel_lay] ~= nil then
                        if config.settings["all"]["all"][sel_lay][var] ~= nil then
                            return config.settings["all"]["all"][sel_lay][var]
                        end
                    end

                    if sel_lay ~= "all" then
                        if config.settings["all"]["all"]["all"] ~= nil then
                            if config.settings["all"]["all"]["all"][var] ~= nil then
                                return config.settings["all"]["all"]["all"][var]
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

config.pget = function(output, tag, layout)
    local o = {}
    o.__index = function(t, var)
        return config.get({output, tag, layout, var})
    end
    setmetatable(o, o)
    return o
end

config.reset = function(sel_out, sel_tag, sel_lay)
    if sel_out == nil then
        sel_out = "all"
    end

    if sel_tag == nil then
        sel_tag = "all"
    end

    if sel_lay == nil then
        sel_lay = "all"
    end

    output = config.settings[sel_out]

    if not output then return end

    tag = output[sel_tag]

    if not tag then return end

    tag[sel_lay] = nil
end

--[[

    NOTE: These functions are global which means they are all callable as a
    layout command. When a layout command is called the global variables
    CMD_OUTPUT and CMD_TAGS are set to the current output and the current tag
    respectively.

--]]

function set(var, val, min, max)
    local layout = config.get({CMD_OUTPUT, CMD_TAGS, nil, "layout"})
    if var == "layout" or not config.get({nil, nil, nil, "per-layout-config"}) then
        layout = nil
    end

    config.set({CMD_OUTPUT, CMD_TAGS, layout, var, val}, {min, max})
end

function inc(var, val)
    local layout = config.get({CMD_OUTPUT, CMD_TAGS, nil, "layout"})
    if var == "layout" or not config.get({nil, nil, nil, "per-layout-config"}) then
        layout = nil
    end

    config.inc({CMD_OUTPUT, CMD_TAGS, layout, var, val})
end

function get(var)
    local layout = config.get({CMD_OUTPUT, CMD_TAGS, nil, "layout"})
    if var == "layout" or not config.get({nil, nil, nil, "per-layout-config"}) then
        layout = nil
    end

    return config.get({CMD_OUTPUT, CMD_TAGS, layout, var})
end

function reset_config()
    local layout = config.get({CMD_OUTPUT, CMD_TAGS, nil, "layout"})
    local sel_layout = layout
    if var == "layout" or not config.get({nil, nil, nil, "per-layout-config"}) then
        sel_layout = nil
    end

    config.reset(CMD_OUTPUT, CMD_TAGS, sel_layout)
    config.set({CMD_OUTPUT, CMD_TAGS, nil, "layout", layout})
end

function set_global(var, val, min, max)
    config.set({nil, nil, nil, var, val}, {min, max})
end

function inc_global(var, val)
    config.inc({nil, nil, nil, var, val})
end

function get_global(var, val)
    return config.get({nil, nil, nil, var})
end

return config

--[[

    TODO: Improve the code for inheriting options and checking that tables exist

--]]
