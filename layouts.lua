local Region = require("backend/region")

---@alias Layout fun(args: LuaArgs, config: Config): WinData[]

---List of layouts that can be selected from.
local layouts = {

    --[[

    Layouts work by filling regions from top to bottom. A region only fills its
    children if enough windows are present to give each child region at least 1
    window. This means that no spaces are left empty by default.

    For correct behaviour make sure that the limit for each region is set correctly.

    --]]

    ---@type Layout
    ---Stacks the windows on top of each other with no offset.
    monocle = function(args, config)
        local r = Region:from_args("top", args):set_layout("fill", {1, nil})

        r.height = r.height - config.offset_top - config.offset_bottom
        r.width = r.width - config.offset_left - config.offset_right
        r.y = r.y + config.offset_top
        r.x = r.x + config.offset_left

        if not (config.smart_gaps) then
            r:set_gaps(config.gaps)
        end

        return r:populate(args.count, config)
    end,

    ---@type Layout
    ---Stacks the windows on top of each other with an offset
    ---so it is clearer that there are multiple windows.
    stack = function(args, config)
        local r = Region:from_args("top", args):set_layout("stack", {1, nil})

        r.height = r.height - config.offset_top - config.offset_bottom
        r.width = r.width - config.offset_left - config.offset_right
        r.y = r.y + config.offset_top
        r.x = r.x + config.offset_left

        r:set_gaps(config.gaps)

        return r:populate(args.count, config)
    end,

    ---@type Layout
    col = function(args, config)
        local r = Region:from_args("top", args):set_layout("rows", {1, nil})

        r.height = r.height - config.offset_top - config.offset_bottom
        r.width = r.width - config.offset_left - config.offset_right
        r.y = r.y + config.offset_top
        r.x = r.x + config.offset_left

        r:set_gaps(config.gaps)

        return r:populate(args.count, config)
    end,

    row = function(args, config)
        local r = Region:from_args("top", args):set_layout("cols", {1, nil})

        r.height = r.height - config.offset_top - config.offset_bottom
        r.width = r.width - config.offset_left - config.offset_right
        r.y = r.y + config.offset_top
        r.x = r.x + config.offset_left

        r:set_gaps(config.gaps)

        return r:populate(args.count, config)
    end,

    ---@type Layout
    ---Arranges the windows in a grid.
    grid = function(args, config)
        local r = Region:from_args("top", args):set_layout("grid", {1, nil})

        r.height = r.height - config.offset_top - config.offset_bottom
        r.width = r.width - config.offset_left - config.offset_right
        r.y = r.y + config.offset_top
        r.x = r.x + config.offset_left

        if not (config.smart_gaps and args.count < 2) then
            r:set_gaps(config.gaps)
        end

        return r:populate(args.count, config)
    end,

    ---@type Layout
    ---@diagnostic disable: unused-local
    main_with_stack = function(args, config)
        local main_ratio = config.main_ratio
        local main_count = config.main_count
        local main_layout = config.main_layout
        local secondary_count = config.secondary_count
        local secondary_ratio = config.secondary_ratio
        local secondary_sublayout = config.secondary_sublayout
        local tertiary_sublayout = config.tertiary_sublayout

        local r = Region:from_args("root", args)

        r.height = r.height - config.offset_top - config.offset_bottom
        r.width = r.width - config.offset_left - config.offset_right
        r.y = r.y + config.offset_top
        r.x = r.x + config.offset_left

        if not (config.smart_gaps and args.count < 2) then
            r:set_gaps(config.gaps)
        end

        -- This is the layout that gets used if there aren't enough windows to
        -- fill the "main" region and the "right" region.
        r:set_layout(main_layout, {1, nil})

        local main_width = math.floor(main_ratio * r.width)

        -- The "main" region should have no more or less than the specified
        -- count. Any less uses the root "r" region and any more spill over
        -- into the "right" region.
        local main = r:from("main", 0, 0, main_width, r.height):set_layout(main_layout, {main_count, main_count})

        -- Force the "main" region to be filled before the "right" region.
        r:next_tier()

        -- Create the overall region for windows to the right of the "main"
        -- region. This will be used when there aren't enough windows to fill
        -- the tertiary region or there is no secondary region.
        local right = r:from("right", main_width, 0, r.width - main_width, r.height)

        -- There is a secondary region
        if secondary_count ~= 0 then
            -- So use the secondary layout if there aren't enough windows to
            -- fill the tertiary region.
            right:set_layout(secondary_sublayout, {1, nil})

            -- Regions are derived from "right" here to make the maths simpler
            -- and restrict the coordinates to being inside the "right" region.
            --
            -- Because we use right:from these regions get put in the "right"
            -- hierarchy. This means to force the secondary region to be filled
            -- before the tertiary region we need to use the "right" hierarchy
            -- as shown below.
            local secondary_height = math.floor(secondary_ratio * right.height)
            local secondary = right:from("secondary", 0, 0, right.width, secondary_height):set_layout(secondary_sublayout, {secondary_count, secondary_count})

            -- Fill the secondary region before attempting to fill the tertiary
            -- region.
            right:next_tier()

            local remaining = right:from("tertiary", 0, secondary_height, right.width, right.height - secondary_height):set_layout(tertiary_sublayout, {1, nil})
        else
            right:set_layout(tertiary_sublayout, {1, nil})
        end

        return r:populate(args.count, config)
    end,

    ---@type Layout
    ---@diagnostic disable: unused-local
    centred = function(args, config)
        local r = Region:from_args("top", args):set_layout(config.main_layout, {1, nil})

        r.height = r.height - config.offset_top - config.offset_bottom
        r.width = r.width - config.offset_left - config.offset_right
        r.y = r.y + config.offset_top
        r.x = r.x + config.offset_left

        if not (config.smart_gaps and args.count < 2) then
            r:set_gaps(config.gaps)
        end

        local main_offset = math.floor(r.width * (0.5 - config.main_ratio / 2))
        local main_width =  math.floor(r.width * config.main_ratio)

        -- If not enough windows are present to totally fill the main region and the two side regions,
        -- fill the main region with as much as we can while leaving two windows free to become the sides
        local main_max = config.main_count
        if args.count < config.main_count + 2 then
            main_max = args.count - 2
        end

        local main = r:from("main", main_offset, 0, main_width, r.height):set_layout(config.main_layout, {1, main_max})

        r:next_tier()

        local left, right

        if config.secondary_count == 0 then
            left = r:from("left_t", 0, 0, main_offset, r.height):set_layout(config.tertiary_sublayout, {1, nil})
            right = r:from("right_t", main_offset + main_width, 0, main_offset, r.height):set_layout(config.tertiary_sublayout, {1, nil})
        else
            local secondary_height = math.floor(r.height * config.secondary_ratio)
            local remaining_offset = secondary_height
            local remaining_height = r.height - remaining_offset

            left = r:from("left", 0, 0, main_offset, r.height):set_layout(config.secondary_sublayout, {1, nil})
            right = r:from("right", main_offset + main_width, 0, main_offset, r.height):set_layout(config.secondary_sublayout, {1, nil})

            local left_top = left:from("left_top", 0, 0, main_offset, secondary_height):set_layout(config.secondary_sublayout, {config.secondary_count, config.secondary_count})

            left:next_tier()

            local left_btm = left:from("left_bot", 0, secondary_height, main_offset, remaining_height):set_layout(config.tertiary_sublayout, {1, nil})

            local right_top = right:from("right_top", 0, 0, main_offset, secondary_height):set_layout(config.secondary_sublayout, {config.secondary_count, config.secondary_count})

            right:next_tier()

            local right_btm = right:from("right_bot", 0, secondary_height, main_offset, remaining_height):set_layout(config.tertiary_sublayout, {1, nil})
        end

        return r:populate(args.count, config)
    end,
}

return layouts
