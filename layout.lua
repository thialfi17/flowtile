
----------------------------------------
--           Module Loading           --
----------------------------------------

-- Setup path to lua modules
config_dir = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
local_dir = config_dir .. "/river-luatile"
package.path = local_dir .. "/?.lua;" .. package.path

-- Globals so that they are accessible through the "run" function below
config = require("config")
layouts = require("layouts")

----------------------------------------
--            User Options            --
----------------------------------------

config.outputs.layout = "main_with_stack"
config.outputs:limit("secondary_count", 0, nil)
config.outputs.secondary_count = 1
config.outputs.main_ratio = 0.6
config.outputs.secondary_ratio = 0.6
config.output["HDMI-A-1"].tags.layout = "grid"

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
    local wins = layouts[config.layout](args, config)
    return wins
end

----------------------------------------
--        Change Runtime Stuff        --
----------------------------------------

-- CMD_TAGS
-- CMD_OUTPUT
function set(var, val)
    config.output[CMD_OUTPUT].tag[CMD_TAGS][var] = val
end

function inc(var, val)
    config.output[CMD_OUTPUT].tag[CMD_TAGS][var] = val + config.output[CMD_OUTPUT].tag[CMD_TAGS][var]
end

-- Execute arbitrary lua code on the running system. This can be useful for debugging or for live editing of things that weren't intended to be changed
function run(str)
    local v = load(str)
    if v ~= nil then
        v()
    else
        print("Code was invalid!")
    end
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
TODO: Layout specific options that can also be set per output/tag
TODO: Redo the configuration table setup to make it cleaner and easier to extend

--]]
