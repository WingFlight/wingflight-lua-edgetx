local t = {}

t.setWaitMessage = function(title, message, back)
    --wf.print("Setting wait message: "..message)
    if message ~= t.message or (message == t.message and not t.shown) then
        t.message = message
        t.title = title
        t.back = back
        t.shown = false
    end
end

t.clearWaitMessage = function()
    --wf.print("Clearing wait message")
    if not t.message then return end
    t.message = nil
    t.shown = false
end

t.updateWaitMessage = function()
    if not t.message or t.shown then return end

    t.shown = true

    lvgl.clear();

    local lyt = {
        {
            type = "page",
            title = "WingFlight " .. wf.luaVersion,
            subtitle = t.title or "",
            icon = wf.baseDir .. "wf.png",
            back = t.back,
            children = {
                {
                    type = "label", x = 70, y = 16, color = BLACK, font = DBLSIZE, text = t.message or ""
                },
            },
        },
    }

    lvgl.build(lyt)
end

return t