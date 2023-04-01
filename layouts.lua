local Region = require("region")

local layouts = {

    monocle = function(args)
        local r = Region:from_args(args):set_layout("fill")
        local _, wins = r:populate(args.count)
        return wins
    end,

    main_with_stack = function(args)
        r = Region:from_args(args)
        r:from(0, 0, 0.6, 1):set_layout("fill", 1)
        local sub = r:from(0.6, 0, 0.4, 1):set_layout("fill")
        sub:from(0, 0, 1, 0.6):set_layout("fill", 1)
        sub:from(0, 0.6, 1, 0.4):set_layout("rows")
        local _, wins = r:populate(args.count)
        return wins
    end,

    centred = function(args)
        c = Region:from_args(args)
        c:from(0.2, 0, 0.6, 1):set_layout("fill", 1)
        c:from(0, 0, 0.2, 1):set_layout("rows")
        c:from(0.8, 0, 0.2, 1):set_layout("rows")
        local _, wins = c:populate(args.count)
        return wins
    end,
}

return layouts
