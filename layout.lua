
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

    Configuration options can be set with:

        set_global({option}, {val}, {min}, {max})

    Where:
        - {option} should be the option name as a string.
        - {val} should be the option value which can be any type except for a
          table (it will work but it won't inherit properly and will not have
          output/tag specific overrides).
        - {min} is the minimum value the option supports and will be restricted to
        - {max} is the maximum value the option supports and will be restricted to



    To change options at runtime several methods are provided:

        Local option manipulation:

        - set({option}, {val})
        - inc({option}, {val})
        - get({option})
        - reset_config()

        Global option manipulation:

        - set_global({option}, {val})
        - inc_global({option}, {val})
        - get_global({option})

    The 'set' functions will set the value of an option to the provided value.
    The 'inc' functions will increment the option value by the supplied value.
    The 'get' functions will return the value of an option.
    'reset_config' will reset the current options of the current tag/layout.

    The non-global version of the functions will set/inc/get the provided
    option for either:

        - The currently selected layout on the currently selected tag on the
          currently selected layout.
        - The currently selected tag on the currently selected layout.

    The option that is set depends on the value of the "per-layout-config"
    option. If this value is true then all option values are set or retrieved
    from the layout specific version of the option for the currently selected
    layout.



    If more granular control over the options is needed then the config
    interface can be used. There are helper functions which restrict the valid
    values of options and will inherit options from global versions but the
    settings can also be accessed and set directly.

    The config interface provides:

        - config.set({ {output}, {tag}, {layout}, {option}, {val} }, { {min}, {max} })
        - config.inc({ {output}, {tag}, {layout}, {option}, {val} })
        - config.get({ {output}, {tag}, {layout}, {option}, {val} })
        - config.pget({output}, {tag}, {layout})
        - config.reset({output}, {tag}, {layout})

    Any of {output}, {tag} or {layout} can be set to "nil" to access/set global
    versions which will be inherited. The value of "all" will also access/set
    global versions. The value "nil" is translated to "all" internally.

    'config.pget' returns a table which can be accessed with option names to
    get the values of options with all of the inheritance rules that the
    'config.get' or 'get' functions provide. This is the interface that is
    provided to the layouts in <layouts.lua>.

    To access options directly:

        - config.settings[output][tag][layout][option] = val

--]]

set_global("per-layout-config", true)

set_global("secondary_count", 1,   0,   nil)
set_global("main_ratio",      0.6, 0.1, 0.9)
set_global("secondary_ratio", 0.6, 0.1, 0.9)

set_global("gaps",            4,   0,   nil) -- To disable set to 0
set_global("smart_gaps",   true)

set_global("layout", "main_with_stack")

--config.set({ "HDMI-A-1", nil, nil, "layout", "grid"})

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
    local layout = config.get({args.output, args.tags, nil, "layout"})

    if not config.get({nil, nil, nil, "per-layout-config"}) then
        layout = nil
    end

    local config = config.pget(args.output, args.tags, layout)
    local wins = layouts[config.layout](args, config)
    return wins
end

--[[

TODO: Documentation!
TODO: Sublayout config options for layouts
TODO: Write some proper layouts
TODO: Clean up unused functions/features
TODO: Standardize function interfaces

TODO: Can gaps be changed so that if children don't have gaps then they are flush with the edges?

--]]
