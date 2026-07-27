chdir("/SCRIPTS/WF")

local run = nil
local scriptsCompiled = assert(loadScript("COMPILE/scripts_compiled.lua"))()
local useLvgl = false

if scriptsCompiled then
    --print("WF: Before wf.lua: ", collectgarbage("count") * 1024)
    assert(loadScript("wf.lua"))()
    --wf.showMemoryUsage("wf loaded")
    wf.radio = wf.executeScript("radios")
    wf.mspQueue = wf.executeScript("MSP/mspQueue")
    wf.mspHelper = wf.executeScript("MSP/mspHelper")

    local canUseLvgl = wf.executeScript("F/canUseLvgl")()
    if canUseLvgl then
        local settings = wf.loadSettings()
        if settings["useLvgl"] == nil or settings["useLvgl"] == 1 then useLvgl = true end
    end

    if useLvgl then
        run = wf.executeScript("ui_lvgl_runner")
    else
        run = wf.executeScript("ui_lcd")
    end

    wf.isTool = true
else
    run = assert(loadScript("COMPILE/compile.lua"))()
    collectgarbage()
end

return { run = run, useLvgl = useLvgl }
