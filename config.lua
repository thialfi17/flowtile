local utils = require("utils")

----------------------------------------
--           Config Layout            --
----------------------------------------

local config = {}

----------------------------------------
--          Implementation            --
----------------------------------------

config.settings = {}


config.lim = function(var, min, max)
end

config.set = function(args, lim)
    local sel_out = args[1]
    local sel_tag = args[2]
    local sel_lay = args[3]
    local var = args[4]
    local val = args[5]

    if var == nil or type(var) ~= "string" then
        error("Invalid variable name!")
    end

    if lim ~= nil then
        config.lim(var, lim[1], lim[2])
    end


    if sel_out == nil then sel_out = "all" end
    if sel_tag == nil then sel_tag = "all" end
    if sel_lay == nil then sel_lay = "all" end
    
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
    
    local output = config.settings[sel_out]
    if not output then
        sel_out = "all"
        output = config.settings["all"]
    end

    local tag = output[sel_tag]
    if not tag then
        sel_tag = "all"
        tag = output["all"]
    end

    local layout = tag[sel_lay]
    if not layout then
        sel_lay = "all"
        layout = tag["all"]
    end

    if layout and layout[var] ~= nil then
        return layout[var]
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

return config
