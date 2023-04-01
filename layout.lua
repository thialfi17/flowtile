smart_gaps = true
gaps = 5
main_ratio = 0.65
current_layout = "main_and_stacked"

local create_region

cap = function(num, fun)
    return function(tab, args) 
        if not args.count or args.count > num then
            args.count = num
        end
        return fun(tab, args)
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
    main_and_stacked = function(args)
        local ret = {}

        if args.count == 1 then
            return sublayouts.fill(ret, create_region(args, 0, 0, 1, 1))
        end

        local main_area = create_region(args, 0, 0, main_ratio, 1.0, 1)
        ret = sublayouts.fill(ret, main_area)

        local sub_area = create_region(args, main_area.width, 0, 1.0-main_ratio, 1.0, -1)
        return sublayouts.rows(ret, sub_area)
    end,
    main_and_stacked_with_secondary = function(args)
        local ret = {}

        if args.count == 1 then
            return sublayouts.fill(ret, create_region(args, 0, 0, 1, 1))
        end

        local main_area = create_region(args, 0, 0, main_ratio, 1.0, 1)
        ret = sublayouts.fill(ret, main_area)

        if args.count == 2 then
            local sub_area = create_region(args, main_area.width, 0, 1.0-main_ratio, 1.0, -1)
            ret = sublayouts.fill(ret, sub_area)
            return ret
        end

        local sub_area = create_region(args, main_area.width, 0, 1.0-main_ratio, 0.6, 1)
        ret = sublayouts.fill(ret, sub_area)
        local subsub_area = create_region(args, main_area.width, sub_area.height, 1.0-main_ratio, 0.4, -2)
        return sublayouts.rows(ret, subsub_area)
    end,
    monocle = function(args)
        local ret = {}
        return sublayouts.fill(ret, create_region(args, 0, 0, 1.0, 1.0))
    end
}

function apply_layout(args, layout)
    return layouts[layout](args)
end

function select_layout(layout)
    current_layout = layout
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
    print("Resolution: " .. args.width .. "x" .. args.height)
    return apply_layout(args, current_layout)
end

create_region = function(args, x, y, w_ratio, h_ratio, count)
    if count then
        if count < 0 then
            count = args.count + count
        end
    else
        count = args.count
    end

    local t = {}
    t.x = x
    t.y = y
    t.width = math.floor(args.width * w_ratio)
    t.height = math.floor(args.height * h_ratio)
    t.count = count
    t.tags = args.tags
    t.output = args.output
    return t
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
    print(string.rep(' ', indent) .. '{')
    for k, v in pairs(t) do
        if type(v) == 'table' then
            table.print(v, indent + 2)
        else
            print(string.rep(' ', indent) .. '  ' .. k .. ': ' .. v)
        end
    end
    print(string.rep(' ', indent) .. '}')
end
