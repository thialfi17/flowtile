require("backend/config")

----------------------
--   User Options   --
----------------------

set_global("main_ratio",      0.6, 0.1, 0.9)
set_global("main_count",      1,   1,   nil) -- Doesn't make sense not to have at least one main window
set_global("main_layout", "grid")
set_global("secondary_ratio", 0.6, 0.1, 0.9)
set_global("secondary_count", 1,   0,   nil)

set_global("secondary_sublayout", "grid")
set_global("tertiary_sublayout",  "stack")

set_global("gaps",            4,   0,   nil) -- To disable set to 0
set_global("smart_gaps", true)

set_global("layout", "main_with_stack")

-----------------------
-- Sublayout Options --
-----------------------

set_global("max_offset",    30,   0, nil)
set_global("grid_ratio",  16/9, 1/3, 3/1)
