local Region = require("region")

local layouts = {

    --[[

    Layouts work by filling regions from top to bottom. A region only fills its
    children if enough windows are present to give each child region at least 1
    window. This means that no spaces are left empty by default.

    For correct behaviour make sure that the limit for each region is set correctly.

    --]]

    monocle = function(args, config)
        local r = Region:from_args(args):set_layout("fill")
        local _, wins = r:populate(args.count, config)
        return wins
    end,

    grid = function(args, config)
        local r = Region:from_args(args):set_layout("grid")
        local _, wins = r:populate(args.count, config)
        return wins
    end,

    main_with_stack = function(args, config)
        local main_ratio = config.main_ratio
        local secondary_count = config.secondary_count

        local r = Region:from_args(args)

        local main = r:from(0, 0, main_ratio, 1):set_layout("fill", {nil, 1})
        local sub = r:from(main_ratio, 0, 1-main_ratio, 1):set_layout("rows", {1, nil})

        if secondary_count ~= 0 then
            local secondary = sub:from(0, 0, 1, 0.6):set_layout("rows", {secondary_count, secondary_count})
            local remaining = sub:from(0, 0.6, 1, 0.4):set_layout("rows", {1, nil}):fill_last()
        end

        local _, wins = r:populate(args.count, config)
        return wins
    end,

    centred = function(args, config)
        local main_ratio = config.main_ratio

        local c = Region:from_args(args):set_layout("cols")
        c:from(0.5 - main_ratio / 2, 0, main_ratio, 1):set_layout("fill", {nil, 1})
        c:from(0, 0, 0.5 - main_ratio / 2, 1):set_layout("rows")
        c:from(0.5 + main_ratio / 2, 0, 0.5 - main_ratio / 2, 1):set_layout("rows")

        local _, wins = c:populate(args.count, config)
        return wins
    end,

    centred2 = function(args, config)
        local main_ratio = config.main_ratio
        local secondary_ratio = config.secondary_ratio

        local c = Region:from_args(args):set_layout("cols")

        local main = c:from(0.5 - main_ratio / 2, 0, main_ratio, 1):set_layout("fill", 1)

        local left = c:from(0, 0, 0.5 - main_ratio / 2, 1):set_layout("rows")
        local right = c:from(0.5 + main_ratio / 2, 0, 0.5 - main_ratio / 2, 1):set_layout("rows")

        local left_top = left:from(0, 0, 1, secondary_ratio):set_layout("rows", secondary_count)
        local left_btm = left:from(0, secondary_ratio, 1, 1 - secondary_ratio):set_layout("rows")

        local right_top = right:from(0, 0, 1, secondary_ratio):set_layout("rows", secondary_count)
        local right_btm = right:from(0, secondary_ratio, 1, 1 - secondary_ratio):set_layout("rows")

        local _, wins = c:populate(args.count, config)
        return wins
    end,

    centred2 = function(args, config)
        local main_ratio = config.main_ratio
        local secondary_ratio = config.secondary_ratio
        local secondary_count = config.secondary_count

        local c = Region:from_args(args):set_layout("cols")

        local main = c:from(0.5 - main_ratio / 2, 0, main_ratio, 1):set_layout("fill", {nil, 1})

        local left = c:from(0, 0, 0.5 - main_ratio / 2, 1):set_layout("rows", {1,secondary_count + 2})
        local right = c:from(0.5 + main_ratio / 2, 0, 0.5 - main_ratio / 2, 1):set_layout("rows"):fill_last()

        if secondary_count ~= 0 then
            local left_top = left:from(0, 0, 1, secondary_ratio):set_layout("rows", {secondary_count, secondary_count})
            local left_btm = left:from(0, secondary_ratio, 1, 1 - secondary_ratio):set_layout("rows",{1, 2}):fill_last()
        end

        local _, wins = c:populate(args.count, config)
        return wins
    end,
}

return layouts
