# flowtile

This is meant to be a framework for designing custom layouts for
[river-luatile](https://github.com/MaxVerevkin/river-luatile) which is a layout
generator for the [river](https://github.com/riverwm/river) window manager.

Flowtile project was heavily inspired by
[stacktile](https://sr.ht/~leon_plickat/stacktile/) which is why the layouts I
have provided are split into multiple regions with selectable "sublayouts" such
as grid, row, columns, fill and stack.

The code has been written in such a way that I hope it's relatively easy to
expand and add more layouts to suit most use cases. **BEWARE THIS IS STILL A
WIP!** Some interfaces (like the configuration) are likely to change!

# Configuration

User settings should be added in `user_settings.lua`. For most use cases what
you will want to do is configure the value of an option globally - setting the
default value of an option on all outputs, tags and layouts. This is done
using:

```lua
-- Min and max are optional parameters that limit numerical values.
-- These limits are useful for values that might have a keyboard
-- shortcut for incrementing/decrementing them. N.B. They can only
-- be set the first time an option is set!
set_global(opt, val, min, max)

-- Set gaps to 5px with a minimum value of 0 and no maximum
set_global("gaps", 5, 0, nil)
-- Enable smart_gaps, no minimum or maximum is needed since the type isn't
-- numerical
set_global("smart_gaps", true)
-- Prevent the main_ratio setting from being set below 0.1 or above 0.9
set_global("main_ratio", 0.6, 0.1, 0.9)
```

More advanced configuration is described below in [Advanced Configuration](#Advanced-Configuration).

Defaults should be set for you for every option in
`user_settings.lua`, but this may end up out of date and
setting options that no longer exist or not setting
options that do exist.

There is currently no list of options or good way to get the options that are
supported without manually checking what is used in the code. Most options are
only used in `layouts.lua` but some options are used in `layout.lua` or
`sublayouts.lua`.

|Option|Type|Description|Where it is used|
|---|---|---|---|
|per-layout-config|boolean|Enables options to be set per-layout|layout.lua|
|layout|string|Not an option as such but is implemented as one. Sets the current layout of a tag.|layout.lua|
|grid_ratio|float|Sets the target window W/H ratio that the smart grid feature aims for.|sublayouts.lua|
|max_offset|integer|Sets the offset between the top and bottom windows with the stack sublayout.|sublayouts.lua|

# Keybindings

To change the layout and layout settings while flowtile is running you need to add keybindings to
river. e.g.

```bash
riverctl map normal Super G send-layout-cmd luatile 'set("layout", "grid")'
riverctl map normal Super Minus send-layout-cmd luatile 'inc("gaps", -1)'
riverctl map normal Super Equal send-layout-cmd luatile 'inc("gaps", 1)'
```

"Commands" that are sent to river-luatile are actually just Lua code. This
means that to change settings you just need to run Lua code that changes the
settings you want! There are some handy functions setup for you that make
changing settings for the currently focussed tag nice and easy. These are the
"set" and "inc" functions.

# Advanced Configuration

Options follow a rather complex hierarchy in flowtile which allows for a rather
powerful amount of customization. You can set option values per-output, per-tag
or per-layout. This means that it is possible to have one monitor always
default to a vertical layout while any others default to a horizontal layout.

Output|Tag|Layout
---|---|---
Current output | current tag | current layout (If per-layout-config)
Current output | current tag | every layout
Current output | every tag   | every layout
Every output   | every tag   | every layout

The first value that exists is the value that is used. N.B. This search path is
currently hard coded in a pretty gross way, so PRs welcome that improve it!

This hierarchy makes it easy to configure defaults options for specific tags
on a specific monitors.

```lua
-- Defaulting to a particular layout on just one monitor is easy!
-- Set the 9th tag on HDMI-A-1 to monocle layout
config.set({
    output = "HDMI-A-1",
    tag = 2 ^ 8,
    layout = "all",
    opt = "layout",
    val = "monocle",
})
```

It is also possible to configure it so that specific tags on ANY monitor
default to certain values. This is much more complicated though and it is
likely easier to just configure each monitor as needed. If you are using a
laptop or regularly changing your setups then maybe the snippet below will help
you achieve what you want.

```lua
local settings_meta = {}
local output_meta = {}

settings_meta.__index = function(outputs, name)
    local output = { }
    setmetatable(output, output_meta)
    outputs[name] = output
    return output
end
output_meta.__index = function(tags, tag_sel)
    local tag = { }

    if tag_sel == 2 ^ 8 then
        tag.all = { -- Important that this is set on the "all" key
            layout = "monocle",
        }
        -- Alternatively set layout specific options with:
        tag.monocle = {
            gaps = 20,
        }
    end

    tags[tag_sel] = tag
    return tags
end
setmetatable(config.settings, settings_meta)
```
