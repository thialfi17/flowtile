# flowtile

This is meant to be a framework for designing custom layouts for [river-luatile](https://github.com/MaxVerevkin/river-luatile) which is a layout generator for the Linux window manager [river](https://github.com/riverwm/river). The project was heavily inspired by [stacktile]() which is why the layouts I have provided are split into multiple regions with selectable "sublayouts" such as grid, row, columns, fill and stack. The code has been written in such a way that I hope it's relatively easy to expand and add more layouts to suit most use cases. **BEWARE THIS IS STILL A WIP!** Some interfaces (like the configuration) are likely to change!

# Config

Confusingly the main configuration is not done in the file config.lua but instead layout.lua. This is because layout.lua is the file that is executed by river-luatile. I can't think of any good reason why this prevents config.lua being used for actual configuration, so maybe one day I will fix this disaster.

Options follow a rather complex hierarchy in flowtile but one which allows for a rather powerful amount of customization. You can set default option values per output, per tag or per layout. This means that it is possible to have one monitor always default to a vertical layout while any others default to a horizontal layout. Or it is possible to default to a "monocle" layout on tag 9 on every monitor or a combination of both! To understand how to configure this first you have to understand how options are "inherited" or found by the layout generator. Options exist in three hierarchies: outputs -> tags -> layouts. You can specify an option for a specific output, tag or layout or for all of them. To get the value of an option for the current layout the following search path is used:

Output|Tag|Layout
---|---|---
Current output | current tag | current layout
Current output | current tag | every layout
Current output | every tag   | current layout
Current output | every tag   | every layout
Every output   | current tag | current layout
Every output   | current tag | every layout
Every output   | every tag   | current layout
Every output   | every tag   | every layout

The first value that exists is the value that is used.

99% of the time what you probably want to do is set the default value of an option for every output, tag and layout. This can be done using the `set_global(opt, val, min?, max?)` function. This function sets an option to a value and has two optional parameters for a minimum and maximum value that the option should be limited to if it is numeric.

For example:

```lua
set_global("gaps", 4, 0, nil)           -- Defaults to 4px gaps and prevents the user from accidentally
                                        -- setting -ve gap values.

set_global("layout", "main_with_stack") -- Sets the default layout for all outputs, tags and layouts

set_global("per-layout-config", true)   -- If this is set to false it removes the layout from the above
                                        -- search path. This means options like gaps will be the same for
                                        -- every layout on the same tag but can still be set independently
                                        -- for different tags

set_global("main_ratio", 0.6, 0.1, 0.9) -- Prevent the main_ratio setting from being set below 0.1 or
                                        -- above 0.9
```

There is no real list of options. It mainly depends on what options are used within the layouts that are in [layouts.lua](layouts.lua). Some other options that are a bit more hard-coded in or that appear in other files are included below:

|Option|Type|Used|
|---|---|---|
|gaps|integer|region.lua and sublayouts.lua|
|per-layout-config|boolean|layout.lua and config.lua|
|layout|string|config.lua, layouts.lua and region.lua|
|grid_ratio|float|sublayouts.lua|

# Keybindings

To change the layout and layout settings while flowtile is running you need to add keybindings to river. e.g.

```
riverctl map normal Super G send-layout-cmd luatile 'set("layout", "grid")'
riverctl map normal Super Minus send-layout-cmd luatile 'inc("gaps", -1)'
riverctl map normal Super Equal send-layout-cmd luatile 'inc("gaps", 1)'
```

"Commands" that are sent to river-luatile are actually just Lua code. This means that to change settings you just need to run Lua code that changes the settings you want! There are some handy functions setup for you that make changing settings for the currently focussed tag nice and easy. These are the "set" and "inc" functions.
