
----------------------------------------
--           Module Loading           --
----------------------------------------

-- Setup path to lua modules
config_dir = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
local_dir = config_dir .. "/river-luatile"
package.path = local_dir .. "/?.lua;" .. package.path

-- Global to make them accessible through the "run" function
config = require("backend/config")
layouts = require("layouts")

----------------------------------------
--          Luatile Handlers          --
----------------------------------------

---@class WinData
---@field [1] number # The X coordinate of the window
---@field [2] number # The Y coordinate of the window
---@field [3] number # The width of the window
---@field [4] number # The height of the window

---@class LuaArgs
---@field tags number # The selected tags
---@field count number # The number of windows on the selected tags
---@field width number # The width of the output
---@field height number # The height of the output
---@field output string # The selected output
---Arguments provided by luatile to determine the window layout

---Function that is called by luatile to handle the layout.
---@param args LuaArgs
---@return WinData[] wins Array of window positions and dimensions
function handle_layout(args)
    local layout = config.get({
        output = args.output,
        tag = args.tags,
        opt = "layout"
    })

    if not config.get({opt = "per-layout-config"}) then
        layout = nil
    end

    local config = config.pget(args.output, args.tags, layout)
    local wins = layouts[config.layout](args, config)
    return wins
end

---Function that is called by luatile to get the layout name
---@param args LuaArgs
function handle_metadata(args)
    local layout = config.get({
        output = args.output,
        tag = args.tags,
        opt = "layout"
    })

    return { name = layout }
end

----------------------------------------
--      Configuration Interface       --
----------------------------------------
-- NOTE: These functions are global which means they are all callable as a
-- layout command. When a layout command is called the global variables
-- CMD_OUTPUT and CMD_TAGS are set to the current output and the current tag
-- respectively.

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

---Increase the value of an option for the current output and tag by
---the given amount.
---
---@param opt string Option name
---@param val any Value to increase option by
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
---
---@param opt string Option name
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

---Reset the option for the currently selected output and tag (and layout if 'per-layout-config' is
---set).
---@param opt string Option name
function reset(opt)
    local layout = config.get({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        opt = "layout"
    })
    local sel_layout = layout
    if not config.get({ opt = "per-layout-config" }) then
        sel_layout = nil
    end

    config.set({
        output = CMD_OUTPUT,
        tag = CMD_TAGS,
        layout = sel_layout,
        opt = opt,
        val = nil
    })
end

---Reset the options for the currently selected output and tag (and layout if 'per-layout-config' is
---set). Doesn't change the current layout just resets the other options.
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
---
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

---Get the default value of an option for all outputs, tags and layouts.
---
---Unlikely to be useful. You probably want to use `get` or `config.get`
---directly to fine-tune the results.
---
---@param opt string Option name
---@return any # Option value
function get_global(opt)
    return config.get({ opt = opt })
end


----------------------------------------
--         Load User Settings         --
----------------------------------------

require("user_settings")

--[[

TODO: Documentation!
TODO: Clean up unused functions/features
TODO: Standardize function interfaces

TODO: Cleanup hierarchy mess. Anything really complicated should be done on the user end not in the config end.
e.g. for i = 0, 3 do
    config.set({
        output = "HDMI-A-1",
        tag = 2^i,
        opt = "layout",
        val = "monocle",
    })
end
TODO: add window position order info to regions to make moving up and down window stack follow intended region hierarchy
TODO: Can gaps be changed so that if children don't have gaps then they are flush with the edges?

--]]
