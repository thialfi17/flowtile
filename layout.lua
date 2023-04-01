smart_gaps = true
gaps = 5
main_ratio = 0.65
current_layout = "main_and_stacked"

create_region = function(args, x, y, w_ratio, h_ratio, count)
    if count then
        if count < 0 then
            count = args.count + count
        elseif count > args.count then
            count = args.count
        end
    else
        count = args.count
    end

    local t = {}
    x_off = args.x or 0
    y_off = args.y or 0
    t.x = (args.width - x_off) * x + x_off
    t.y = (args.height - y_off) * y + y_off
    t.width = math.floor(args.width * w_ratio)
    t.height = math.floor(args.height * h_ratio)
    t.count = count
    t.tags = args.tags
    t.output = args.output
    return t
end
region = function(x, y, w_ratio, h_ratio)
    return function(args, count)
        return create_region(args, x, y, w_ratio, h_ratio, count)
    end
end

sublayouts = {
    fill = function(tab, args)
        local ret = table.copy(tab)
        for i = 1, args.count do
            table.insert(ret, {args.x, args.y, args.width, args.height}) 
        end
        return ret
    end,
    rows = function(tab, args)
        local height = args.height / args.count
        for i = 0, args.count-1 do
            table.insert(tab, {args.x, args.y + height*i, args.width, height})
        end
        return tab
    end,
}

layouts = {
    main_and_stacked = {
        {
            area = region(0, 0, main_ratio, 1.0),
            remaining = region(main_ratio, 0, 1.0-main_ratio, 1.0),
            fill_remaining = true,
            max_count = 1,
            sublayout = "fill",
        },
        {
            area = region(0, 0, 1.0, 1.0),
            remaining = nil,
            max_count = nil,
            sublayout = "rows",
        }
    },
    centred_with_sidebars = {
        {
            area = region(0.2, 0, 0.6, 1.0),
            remaining = region(0, 0, 0.2, 1.0),
            max_count = 1,
            fill_remaining = false,
            sublayout = "fill",
        },
        {
            area = region(0, 0, 1.0, 1.0),
            remaining = nil,
            max_count = nil,
            sublayout = "rows",
        }
    },
    main_and_stacked_with_secondary = {
        {
            area = region(0, 0, main_ratio, 1.0),
            remaining = region(main_ratio, 0, 1-main_ratio, 1.0),
            fill_remaining = true,
            max_count = 1,
            sublayout = "fill",
        },
        {
            area = region(0, 0, 1.0, 0.6),
            remaining = region(0, 0.6, 1.0, 0.4),
            fill_remaining = true,
            max_count = 1,
            sublayout = "rows",
        },
        {
            area = region(0, 0, 1.0, 1.0),
            remaining = nil,
            max_count = nil,
            sublayout = "rows",
        },
    },
    monocle = {
        {
            area = region(0, 0, 1.0, 1.0),
            remaining = nil,
            max_count = nil,
            sublayout = "fill",
        }
    },
}

function apply_layout(args, layout)
    local count = 0
    local ret = {}
    local remaining = create_region(args, 0, 0, 1.0, 1.0)

    for i, v in ipairs(layouts[layout]) do
        if v.max_count and count + v.max_count >= args.count and v.fill_remaining then
            ret = sublayouts[v.sublayout](ret, remaining)
            return ret
        end

        ret = sublayouts[v.sublayout](ret, v.area(remaining, v.max_count))

        if v.remaining then
            remaining = v.remaining(remaining, -v.max_count)
        end

        if not v.max_count then
            return ret
        else
            count = count + v.max_count

            if count >= args.count then
                return ret
            end
        end
    end
    return ret
end

function select_layout(layout)
    current_layout = layout
end

function set_ratio(rat)
    main_ratio = rat
end

-- args:
--  * tags: focused tags
--  * count: window count
--  * width: output width
--  * height: output height
--  * output: output name
--
-- should return a table with exactly `count` entries. Each entry is 4 numbers:
--  * X
--  * Y
--  * width
--  * height
function handle_layout(args)
    return apply_layout(args, current_layout)
end

table.copy = function(t)
    local t2 = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            t2[k] = table.copy(v)
        else
            t2[k] = v
        end
    end
    return t2
end
table.print = function(t, indent)
    if not indent then indent = 0 end
    local pre = string.rep(' ', indent)
    print(pre .. '{')
    for k, v in pairs(t) do
        if type(v) == 'table' then
            table.print(v, indent + 2)
        elseif type(v) == 'function' then
            print(pre .. '  ' .. k .. ' = ' .. tostring(v))
        else
            print(pre .. '  ' .. k .. ' = ' .. tostring(v))
        end
    end
    print(pre .. '}')
end
