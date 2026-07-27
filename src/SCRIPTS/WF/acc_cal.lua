local mspAccCalibration = wf.useApi("mspAccCalibration")
local sentCalibrate = false

local function calibrate()
    if not sentCalibrate then
        mspAccCalibration.calibrate()
        sentCalibrate = true
    end

    wf.mspQueue:processQueue()

    return wf.mspQueue:isProcessed()
end

return { f = calibrate, t = "Calibrating Accelerometer" }
