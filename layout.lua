
----------------------------------------
--           Module Loading           --
----------------------------------------

-- Setup path to lua modules
config_dir = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
local_dir = config_dir .. "/river-luatile"
package.path = local_dir .. "/?.lua;" .. package.path

-- Global to make them accessible through the "run" function
config = require("backend/config")
layouts = require("layouts")

-- Load user settings
require("user_settings")

----------------------------------------
--            Layout Code             --
----------------------------------------

---@class WinData
---@field [1] number # The X coordinate of the window
---@field [2] number # The Y coordinate of the window
---@field [3] number # The width of the window
---@field [4] number # The height of the window

---@class LuaArgs
---@field tags number # The selected tags
---@field count number # The number of windows on the selected tags
---@field width number # The width of the output
---@field height number # The height of the output
---@field output string # The selected output
---Arguments provided by luatile to determine the window layout

---Function that is called by luatile to handle the layout.
---@param args LuaArgs
---@return WinData[] wins Array of window positions and dimenions
function handle_layout(args)
    local layout = config.get({
        output = args.output,
        tag = args.tags,
        opt = "layout"
    })

    if not config.get({opt = "per-layout-config"}) then
        layout = nil
    end

    local config = config.pget(args.output, args.tags, layout)
    local wins = layouts[config.layout](args, config)
    return wins
end

--[[

TODO: Documentation!
TODO: Clean up unused functions/features
TODO: Standardize function interfaces

TODO: cleanup hierarchy changes
TODO: add window position order info to regions to make moving up and down window stack follow intended region hierarchy
TODO: Can gaps be changed so that if children don't have gaps then they are flush with the edges?

--]]
