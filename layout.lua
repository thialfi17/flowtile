config_dir = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
local_dir = config_dir .. "/river-luatile"
package.path = local_dir .. "/?.lua;" .. package.path

----------------------------------------
--            User Options            --
----------------------------------------

local config = require("config")
local layouts = require("layouts")

config.outputs.layout:set("main_with_stack")
config.outputs.secondary_count:set(1)
config.output["HDMI-A-1"].layout:set("grid")

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
    --print("Running and setting layout")
    --local u = require("utils")
    --print("Global:")
    --u.table.print(config.outputs.secondary_count, 0, false)
    --print("Local:")
    --u.table.print(config.output[args.output].secondary_count, 0, false)

    local config = config.output[args.output].tag[args.tags]
    local wins = layouts[config.layout:get()](args, config)
    return wins
end

----------------------------------------
--        Change Runtime Stuff        --
----------------------------------------

-- CMD_TAGS
-- CMD_OUTPUT
function set(var, val)
    config.output[CMD_OUTPUT].tag[CMD_TAGS][var]:set(val)
end

function inc(var, val)
    config.output[CMD_OUTPUT].tag[CMD_TAGS][var]:inc(val)
end

function debug()
    local u = require("utils")
    print("Output: " .. CMD_OUTPUT)
    print("Tags: " .. CMD_TAGS)
    u.table.print(config)
end

--[[

TODO: Document configuration and inheritance
TODO: Further consideration needed for inheritance rules for config
TODO: Add gaps/smart gaps

--]]
