config_dir = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
local_dir = config_dir .. "/river-luatile"
package.path = local_dir .. "/?.lua;" .. package.path

----------------------------------------
--            User Options            --
----------------------------------------

config = require("config")
layouts = require("layouts")

config.outputs.layout = "main_with_stack"
config.output["HDMI-A-1"].layout = "grid"

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
    output = args.output
    tag = args.tags
    return layouts[config.output[output].tag[tag].layout](args)
end

----------------------------------------
--        Change Runtime Stuff        --
----------------------------------------

function set_layout(layout)
    config.output[output].tag[tag].layout = layout
end

--[[

TODO: Document configuration and inheritance
TODO: Add gaps/smart gaps
TODO: Make use of options
TODO: Add commands to set options

--]]
