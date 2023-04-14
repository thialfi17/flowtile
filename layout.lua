
----------------------------------------
--           Module Loading           --
----------------------------------------

-- Setup path to lua modules
config_dir = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
local_dir = config_dir .. "/river-luatile"
package.path = local_dir .. "/?.lua;" .. package.path

-- Global to make them accessible through the "run" function
config = require("config")
layouts = require("layouts")

----------------------------------------
--            User Options            --
----------------------------------------

--[[

    Reserved option names are: print, limit, iter, and new

--]]

config.set({nil, nil, "secondary_count", 1  }, {0,   nil})
config.set({nil, nil, "main_ratio",      0.6}, {0.1, 0.9})
config.set({nil, nil, "secondary_ratio", 0.6}, {0.1, 0.9})

config.set({nil, nil, "gaps",          4}, {0, nil})
config.set({nil, nil, "smart_gaps", true})

config.outputs.layout = "main_with_stack"

----------------------------------------
--            Layout Code             --
----------------------------------------

-- args:
--  * tags: focused tags
--  * count: window count
--  * width: output width
--  * height: output height
--  * output: output name
--
-- should return a table with exactly `count` entries. Each entry is 4 numbers:
--  * X
--  * Y
--  * width
--  * height
function handle_layout(args)
    local config = config.output[args.output].tag[args.tags]
    local wins = layouts[config.layout](args, config)
    return wins
end

----------------------------------------
--        Change Runtime Stuff        --
----------------------------------------

--[[

    These functions are all callable as a layout command. When a layout
    command is called the global variables CMD_OUTPUT and CMD_TAGS are set
    to the current output and the current tag respectively.

--]]

function set(var, val)
    config.set({CMD_OUTPUT, CMD_TAGS, var, val})
end

function inc(var, val)
    config.inc({CMD_OUTPUT, CMD_TAGS, var, val})
end

function set_global(var, val)
    config.set({nil, nil, var, val})
end

function inc_global(var, val)
    config.inc({nil, nil, var, val})
end

-- Execute arbitrary lua code on the running system. This can be useful for
-- debugging or for live editing of things that weren't intended to be changed
function run(str)
    local v = load(str)
    if v ~= nil then
        v()
    else
        print("Code was invalid!")
    end
end

--[[

TODO: Documentation!
TODO: Layout specific options that can also be set per output/tag
TODO: Region layout generation that uses full space and doesn't have rounding errors
TODO: Sublayout config options for layouts
TODO: Write some proper layouts
TODO: Clean up unused functions/features

--]]
