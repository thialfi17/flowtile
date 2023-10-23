---@alias Config {[string]: any}

local config = {}

config.settings = {}
config.restrict = {}

---Limit an option to be of a specific type with optional upper and lower bounds if the type is a
---"number". If option already exists and has an associated type then check that the types are the
---same.
---
---@param opt string Option name
---@param val any Option value
---@param min? number Lower bound. Option is set to this value if val is too small.
---@param max? number Upper bound. Option is set to this value if val is too big.
---@return boolean success # If val was a compatible type with opt.
---@return any val # The value of val limited between min and max (if val is a number).
config.lim = function(opt, val, min, max)
    if config.restrict[opt] then
        local restrict = config.restrict[opt]
        if type(val) ~= restrict.type then
            print("Incompatible type for setting " .. opt .. "(" .. type(val) .. " ~= " .. restrict.type .. ")")
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
        config.restrict[opt] = {
            type = type(val),
            min = min,
            max = max,
        }
        return true, val
    end
end

---Set the value of an option for the specified output, tags and layout.
---@param args { output?: string, tag?: number|string, layout?: string, opt: string, val: any, min?: number, max?: number}
config.set = function(args)
    local sel_out = args.output
    local sel_tag = args.tag
    local sel_lay = args.layout
    local opt = args.opt
    local val = args.val
    local min = args.min
    local max = args.max

    if opt == nil or type(opt) ~= "string" then
        error("Invalid variable name!")
    end

    local pass
    pass, val = config.lim(opt, val, min, max)

    if not pass then return end

    if sel_out == nil then sel_out = "all" end
    if sel_tag == nil then sel_tag = "all" end
    if sel_lay == nil then sel_lay = "all" end

    if (config.settings.all == nil or config.settings.all.all == nil or config.settings.all.all.all[opt] == nil) and (sel_out ~= "all" or sel_tag ~= "all" or sel_lay ~= "all") then
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

        layout[opt] = val
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

    layout[opt] = val
end

config.inc = function(args)
    local val = config.get(args)

    args.val = args.val + val

    config.set(args)
end

---@param args {output?: string, tag?: number|string, layout?: string, opt: string}
---@return any val
config.get = function(args)
    local sel_out = args.output
    local sel_tag = args.tag
    local sel_lay = args.layout
    local opt = args.opt

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

    local value = config.settings[sel_out][sel_tag][sel_lay][opt]
    if value ~= nil then
        return value
    end

    if sel_lay ~= "all" then
        if config.settings[sel_out][sel_tag]["all"] ~= nil then
            if config.settings[sel_out][sel_tag]["all"][opt] ~= nil then
                return config.settings[sel_out][sel_tag]["all"][opt]
            end
        end
    end

    if sel_tag ~= "all" then
        if config.settings[sel_out]["all"] ~= nil then
            if config.settings[sel_out]["all"][sel_lay] ~= nil then
                if config.settings[sel_out]["all"][sel_lay][opt] ~= nil then
                    return config.settings[sel_out]["all"][sel_lay][opt]
                end
            end

            if sel_lay ~= "all" then
                if config.settings[sel_out]["all"]["all"] ~= nil then
                    if config.settings[sel_out]["all"]["all"][opt] ~= nil then
                        return config.settings[sel_out]["all"]["all"][opt]
                    end
                end
            end
        end
    end

    if sel_out ~= "all" then
        if config.settings["all"] ~= nil then
            if config.settings["all"][sel_tag] ~= nil then
                if config.settings["all"][sel_tag][sel_lay] ~= nil then
                    if config.settings["all"][sel_tag][sel_lay][opt] ~= nil then
                        return config.settings["all"][sel_tag][sel_lay][opt]
                    end
                end
                if config.settings["all"][sel_tag]["all"] ~= nil then
                    if config.settings["all"][sel_tag]["all"][opt] ~= nil then
                        return config.settings["all"][sel_tag]["all"][opt]
                    end
                end
            end


            if sel_tag ~= "all" then
                if config.settings["all"]["all"] ~= nil then
                    if config.settings["all"]["all"][sel_lay] ~= nil then
                        if config.settings["all"]["all"][sel_lay][opt] ~= nil then
                            return config.settings["all"]["all"][sel_lay][opt]
                        end
                    end

                    if sel_lay ~= "all" then
                        if config.settings["all"]["all"]["all"] ~= nil then
                            if config.settings["all"]["all"]["all"][opt] ~= nil then
                                return config.settings["all"]["all"]["all"][opt]
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

---Convenience wrapper for accessing multiple options for a specific output, tag and layout.
---
---@param output? string Output. A value of "nil" resets the fallback options.
---@param tag? number Tag. A value of "nil" resets the fallback options.
---@param layout? string Layout. A value of "nil" resets the fallback options.
---@return Config # Table whose keys are the options for the given output, tag and layout.
config.pget = function(output, tag, layout)
    local o = {}
    o.__index = function(_, opt)
        return config.get({ output = output, tag = tag, layout = layout, opt = opt })
    end
    setmetatable(o, o)
    return o
end

---Reset all of the options for a specific output, tag and layout.
---
---@param sel_out? string Output. A value of "nil" resets the fallback options.
---@param sel_tag? string Tag. A value of "nil" resets the fallback options.
---@param sel_lay? string Layout. A value of "nil" resets the fallback options.
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

    local output = config.settings[sel_out]

    if not output then return end

    local tag = output[sel_tag]

    if not tag then return end

    tag[sel_lay] = nil
end

--[[

    NOTE: These functions are global which means they are all callable as a
    layout command. When a layout command is called the global variables
    CMD_OUTPUT and CMD_TAGS are set to the current output and the current tag
    respectively.

--]]

---Set the value of an option for the current output and tag and optionally provide upper and lower
---bounds. If the 'per-layout-config' is set option is set for the current layout.
---
---@param opt string Option name
---@param val any Option value
---@param min? number Lower bound for 'number' option value
---@param max? number Upper bound for 'number' option value
function set(opt, val, min, max)
    local layout = config.get({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        opt = "layout"
    })
    if opt == "layout" or not config.get({ opt = "per-layout-config" }) then
        layout = nil
    end

    config.set({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        layout = layout,
        opt = opt,
        val = val,
        min = min,
        max = max
    })
end

function inc(opt, val)
    local layout = config.get({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        opt = "layout"
    })
    if opt == "layout" or not config.get({ opt = "per-layout-config" }) then
        layout = nil
    end

    config.inc({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        layout = layout,
        opt = opt,
        val = val
    })
end

---Get the value of an option for the current output and tag. If the 'per-layout-config' option is
---set, the value of the option for the currentl layout is returned.
---@return any # The value of the option
function get(opt)
    local layout = config.get({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        opt = "layout"
    })
    if opt == "layout" or not config.get({ opt = "per-layout-config" }) then
        layout = nil
    end

    return config.get({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        layout = layout,
        opt = opt
    })
end

---Reset the options for the currently selected output and tag (and layout if 'per-layout-config' is
---set).
function reset_config()
    local layout = config.get({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        opt = "layout"
    })
    local sel_layout = layout
    if not config.get({ opt = "per-layout-config" }) then
        sel_layout = nil
    end

    config.reset(CMD_OUTPUT, CMD_TAGS, sel_layout)
    config.set({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        opt = "layout",
        val = layout
    })
end

---Set the default value of an option for all outputs, tags and layouts.
---@param opt string Option name
---@param val any Option value
---@param min? number Minimum option value if a number
---@param max? number Maximum option value if a number
function set_global(opt, val, min, max)
    config.set({
        opt = opt,
        val = val,
        min = min,
        max = max
    })
end

function inc_global(opt, val)
    config.inc({ opt = opt, val = val })
end

function get_global(opt)
    return config.get({ opt = opt })
end

return config
