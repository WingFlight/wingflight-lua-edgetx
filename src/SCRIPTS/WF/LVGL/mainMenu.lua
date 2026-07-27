local function show(menu)
    lvgl.clear()

    local children = {}
    local w = (LCD_W - 30) / 3
    local screenMult = wf.radio.screenMult or 1
    local h = 50 * screenMult

    for i = 1, #menu.items do
        local item = menu.items[i]
        children[#children + 1] = {
            type = "button",
            x = 6 + #children % 3 * (w + (4 * screenMult)),
            y = 6 + math.floor(#children / 3) * (h + (4 * screenMult)),
            w = w,
            h = h,
            text = item.text,
            press = function()
                if item.click then
                    item.click(i)
                end
            end
        }
    end

    local subtitle = wf.executeScript("F/getLvglSubtitle", menu.subtitle) -- EdgeTX < 2.11.4 don't support functions as argument for subtitle

    local lyt = {
        {
            type = "page",
            title = menu.title,
            subtitle = subtitle,
            icon = wf.baseDir .. "wf.png",
            back = function()
                if menu.back then
                    menu.back()
                end
            end,
            children = children
        },
    }

    lvgl.build(lyt)
end

return { show = show }