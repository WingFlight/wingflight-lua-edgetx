local initialized = false
local backgroundTask = nil

local function startup()
    if not initialized then
        assert(loadScript("/SCRIPTS/WF/wf.lua"))()
        wf.mspQueue = wf.executeScript("MSP/mspQueue")
        wf.mspHelper = wf.executeScript("MSP/mspHelper")
        backgroundTask = wf.executeScript("background")
        initialized = true
    else
        backgroundTask()
    end
end

return { run = startup }
