----------------------------------------
--            User Options            --
----------------------------------------

smart_gaps = true
gaps = 5
main_ratio = 0.70
current_layout = "main_with_stack"

----------------------------------------
--            Layout Code             --
----------------------------------------

config_dir = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
local_dir = config_dir .. "/river-luatile"
package.path = local_dir .. "/?.lua;" .. package.path

layouts = require("layouts")
utils = require("utils")

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
    return layouts[current_layout](args)
end

function set_layout(layout)
    current_layout = layout
end

-- If there aren't enough windows to fill all of the children then fill the parent (optional?)
--   - what happens if there are three children but only one window? control this behaviour with an option?
-- Each region has a method of filling it
-- Each tag should have a hierarchy of regions
