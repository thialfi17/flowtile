----------------------
--   User Options   --
----------------------
-- These are global options that affect how the layouts are generated. All
-- options that are used in ANY layout should have a value set below.
--
-- NOTE: Not all options are used for all layouts.
--
-- It is recommended to install the luals LSP to provide signature help for
-- built-in functions. If you can't install the LSP then either refer to any
-- documentation or read through the source code. The signature for the
-- set_global function has been provided below:
--
--   set_global( "option", VALUE, MIN, MAX )
--
-- If you have modified any of the layout code you may find adding more debug
-- messages useful. To set the log level to include debug messages uncomment the
-- following line:
--
-- require("backend.utils").set_log_level(DEBUG)
--
-- NOTE: There aren't many debug messages included by default at the moment.

set_global("per-layout-config", true)

set_global("main_ratio",        0.6, 0.1, 0.9)
set_global("main_count",        1,   1,   nil) -- Doesn't make sense not to have at least one main window
set_global("main_layout",       "grid")

set_global("secondary_ratio",       0.6, 0.1, 0.9)
set_global("secondary_count",       1,   0,   nil)
set_global("secondary_sublayout",   "grid")

set_global("tertiary_sublayout",    "stack")

set_global("gaps", 4,   0,   nil) -- To disable set to 0
set_global("smart_gaps",   false)

set_global("layout", "main_with_stack")

-- Move the entire region of tiled windows away from the edges.
-- Can be useful for creating a region to put floating windows or for
-- edge-specific gaps.
set_global("offset_top",    0, 0, nil)
set_global("offset_bottom", 0, 0, nil)
set_global("offset_left",   0, 0, nil)
set_global("offset_right",  0, 0, nil)

-----------------------
-- Sublayout Options --
-----------------------
-- No different from the other global options except for where they are used.

-- Maximum offset of `stack` sublayout
set_global("max_offset",    30,   0, nil)
-- Target ratio the grid sublayout aims for
set_global("grid_ratio",  16/9, 1/3, 3/1)

-----------------------
--    Tag Options    --
-----------------------
-- TODO: Add configuration examples for tag specific options.
-- TODO: Configuration for scratch tag.
