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
        local r = Region:from_args("top", args):set_layout("fill")

        if not (config.smart_gaps) then
            r:set_gaps(config.gaps)
        end

        return r:populate(args.count, config)
    end,

    ---@type Layout
    ---Stacks the windows on top of each other with an offset
    ---so it is clearer that there are multiple windows.
    stack = function(args, config)
        local r = Region:from_args("top", args):set_layout("stack")

        r:set_gaps(config.gaps)

        return r:populate(args.count, config)
    end,

    ---@type Layout
    col = function(args, config)
        local r = Region:from_args("top", args):set_layout("rows")

        r:set_gaps(config.gaps)

        return r:populate(args.count, config)
    end,

    row = function(args, config)
        local r = Region:from_args("top", args):set_layout("cols")

        r:set_gaps(config.gaps)

        return r:populate(args.count, config)
    end,

    ---@type Layout
    ---Arranges the windows in a grid.
    grid = function(args, config)
        local r = Region:from_args("top", args):set_layout("grid")

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

        local r = Region:from_args("top", args)

        if not (config.smart_gaps and args.count < 2) then
            r:set_gaps(config.gaps)
        end

        local main_width = math.floor(main_ratio * r.width)

        local main = r:from("main", 0, 0, main_width, r.height):set_layout(main_layout, {main_count, main_count})

        r:next_tier()

        local sub = r:from("right", main_width, 0, r.width - main_width, r.height)

        if secondary_count ~= 0 then
            sub:set_layout(secondary_sublayout, {1, nil})

            local secondary_height = math.floor(secondary_ratio * sub.height)
            local secondary = sub:from("secondary", 0, 0, sub.width, secondary_height):set_layout(secondary_sublayout, {secondary_count, secondary_count})

            sub:next_tier()

            local remaining = sub:from("tertiary", 0, secondary_height, sub.width, sub.height - secondary_height):set_layout(tertiary_sublayout, {1, nil})
        else
            sub:set_layout(tertiary_sublayout, {1, nil})
        end

        return r:populate(args.count, config)
    end,

    ---@type Layout
    ---@diagnostic disable: unused-local
    centred = function(args, c)
        local r = Region:from_args("top", args):set_layout(c.main_layout)

        if not (c.smart_gaps and args.count < 2) then
            r:set_gaps(c.gaps)
        end

        local main_offset = math.floor(r.width * (0.5 - c.main_ratio / 2))
        local main_width =  math.floor(r.width * c.main_ratio)

        -- If not enough windows are present to totally fill the main region and the two side regions,
        -- fill the main region with as much as we can while leaving two windows free to become the sides
        local main_max = c.main_count
        if args.count < c.main_count + 2 then
            main_max = args.count - 2
        end

        local main = r:from("main", main_offset, 0, main_width, r.height):set_layout(c.main_layout, {1, main_max})

        r:next_tier()

        local left, right

        if c.secondary_count == 0 then
            left = r:from("left_t", 0, 0, main_offset, r.height):set_layout(c.tertiary_sublayout, {1, nil})
            right = r:from("right_t", main_offset + main_width, 0, main_offset, r.height):set_layout(c.tertiary_sublayout, {1, nil})
        else
            local secondary_height = math.floor(r.height * c.secondary_ratio)
            local remaining_offset = secondary_height
            local remaining_height = r.height - remaining_offset

            left = r:from("left", 0, 0, main_offset, r.height):set_layout(c.secondary_sublayout, {1, nil})
            right = r:from("right", main_offset + main_width, 0, main_offset, r.height):set_layout(c.secondary_sublayout, {1, nil})

            local left_top = left:from("left_top", 0, 0, main_offset, secondary_height):set_layout(c.secondary_sublayout, {c.secondary_count, c.secondary_count})

            left:next_tier()

            local left_btm = left:from("left_bot", 0, secondary_height, main_offset, remaining_height):set_layout(c.tertiary_sublayout)

            local right_top = right:from("right_top", 0, 0, main_offset, secondary_height):set_layout(c.secondary_sublayout, {c.secondary_count, c.secondary_count})

            right:next_tier()

            local right_btm = right:from("right_bot", 0, secondary_height, main_offset, remaining_height):set_layout(c.tertiary_sublayout)
        end

        return r:populate(args.count, c)
    end,
}

return layouts
