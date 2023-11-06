local Region = require("backend/region")

local layouts = {

    --[[

    Layouts work by filling regions from top to bottom. A region only fills its
    children if enough windows are present to give each child region at least 1
    window. This means that no spaces are left empty by default.

    For correct behaviour make sure that the limit for each region is set correctly.

    --]]

    monocle = function(args, config)
        local r = Region:from_args(args):set_layout("fill")

        if not (config.smart_gaps) then
            r:set_gaps(config.gaps)
        end

        local wins = r:populate(args.count, config)
        return wins
    end,

    stack = function(args, config)
        local r = Region:from_args(args):set_layout("stack")

        r:set_gaps(config.gaps)

        local wins = r:populate(args.count, config)
        return wins
    end,

    grid = function(args, config)
        local r = Region:from_args(args):set_layout("grid")

        if not (config.smart_gaps and args.count < 2) then
            r:set_gaps(config.gaps)
        end

        local wins = r:populate(args.count, config)
        return wins
    end,

    main_with_stack = function(args, config)
        local main_ratio = config.main_ratio
        local main_count = config.main_count
        local main_layout = config.main_layout
        local secondary_count = config.secondary_count
        local secondary_ratio = config.secondary_ratio
        local secondary_sublayout = config.secondary_sublayout
        local tertiary_sublayout = config.tertiary_sublayout

        local r = Region:from_args(args)

        if not (config.smart_gaps and args.count < 2) then
            r:set_gaps(config.gaps)
        end

        local main_width = math.floor(main_ratio * r.width)

        local main = r:from(0, 0, main_width, r.height):set_layout(main_layout, {main_count, main_count})
        r:next_tier()
        local sub = r:from(main_width, 0, r.width - main_width, r.height)

        if secondary_count ~= 0 then
            sub:set_layout(secondary_sublayout, {1, nil})
            local secondary_height = math.floor(secondary_ratio * sub.height)
            local secondary = sub:from(0, 0, sub.width, secondary_height):set_layout(secondary_sublayout, {secondary_count, secondary_count})
            r:next_tier()
            local remaining = sub:from(0, secondary_height, sub.width, sub.height - secondary_height):set_layout(tertiary_sublayout, {1, nil})
        else
            sub:set_layout(tertiary_sublayout, {1, nil})
        end

        local wins = r:populate(args.count, config)
        return wins
    end,

    centred = function(args, config)
        local main_ratio = config.main_ratio
        local main_count = config.main_count
        local main_layout = config.main_layout
        local secondary_ratio = config.secondary_ratio
        local secondary_count = config.secondary_count
        local secondary_sublayout = config.secondary_sublayout
        local tertiary_sublayout = config.tertiary_sublayout

        local c = Region:from_args(args):set_layout(main_layout)

        if not (config.smart_gaps and args.count < 2) then
            c:set_gaps(config.gaps)
        end

        local main_offset = math.floor(c.width * (0.5 - main_ratio / 2))
        local main_width =  math.floor(c.width * main_ratio)

        local main_max = main_count
        if args.count < main_count + 2 then
            main_max = args.count - 2
        end
        local main = c:from(main_offset, 0, main_width, c.height):set_layout(main_layout, {1, main_max})

        c:next_tier()

        local left, right

        if secondary_count == 0 then
            left = c:from(0, 0, main_offset, c.height):set_layout(tertiary_sublayout, {1, nil})
            right = c:from(main_offset + main_width, 0, main_offset, c.height):set_layout(tertiary_sublayout, {1, nil})
        else
            left = c:from(0, 0, main_offset, c.height):set_layout(secondary_sublayout, {1, nil})
            right = c:from(main_offset + main_width, 0, main_offset, c.height):set_layout(secondary_sublayout, {1, nil})
        end

        if secondary_count ~= 0 then
            local secondary_height = math.floor(c.height * secondary_ratio)
            local remaining_offset = secondary_height
            local remaining_height = c.height - remaining_offset

            local left_top = left:from(0, 0, main_offset, secondary_height):set_layout(secondary_sublayout, {secondary_count, secondary_count})
            left:next_tier()
            local left_btm = left:from(0, secondary_height, main_offset, remaining_height):set_layout(tertiary_sublayout)

            local right_top = right:from(0, 0, main_offset, secondary_height):set_layout(secondary_sublayout, {secondary_count, secondary_count})
            right:next_tier()
            local right_btm = right:from(0, secondary_height, main_offset, remaining_height):set_layout(tertiary_sublayout)
        end

        local wins = c:populate(args.count, config)
        return wins
    end,
}

return layouts
