-- MSP2_WING_TUNE_ADVISOR (0x5F18, read one axis) and MSP2_WING_TUNE_ADVISOR_CLEAR (0x5F19).
-- One axis per request so the reply (65 bytes) fits MSP over telemetry. Layout: see
-- wingflight-firmware src/main/msp/msp.c. Firmware without them answers with an error.

local function readRatio(buf)
    local v = wf.mspHelper.readU16(buf)
    if v >= 0x8000 then v = v - 0x10000 end
    return v / 1000
end

local function readBands(buf)
    local bands = {}
    for i = 1, 3 do
        bands[i] = { gain = readRatio(buf), count = wf.mspHelper.readU16(buf) }
    end
    return bands
end

-- axis: 0 roll, 1 pitch, 2 yaw
local function getAxis(axis, callback, callbackParam, errorCallback)
    local message = {
        command = 0x5F18,
        payload = { axis },
        processReply = function(self, buf)
            local d = {}
            d.version = wf.mspHelper.readU8(buf)
            d.collecting = wf.mspHelper.readU8(buf) ~= 0
            d.seconds = wf.mspHelper.readU16(buf)
            d.axis = wf.mspHelper.readU8(buf)
            d.P = wf.mspHelper.readU16(buf)
            d.F = wf.mspHelper.readU16(buf)
            d.B = wf.mspHelper.readU16(buf)
            d.relax = wf.mspHelper.readU8(buf)
            d.rcRate = wf.mspHelper.readU8(buf)
            d.ffCount = wf.mspHelper.readU16(buf)
            d.ffGain = readRatio(buf)
            d.ffCorr = readRatio(buf)
            d.ffLagMs = wf.mspHelper.readU16(buf)
            d.spBands = readBands(buf)
            d.thrBands = readBands(buf)
            d.fullCount = wf.mspHelper.readU16(buf)
            d.fullSatCount = wf.mspHelper.readU16(buf)
            d.fullRatio = readRatio(buf)
            d.fullMaxRate = wf.mspHelper.readU16(buf)
            d.releases = wf.mspHelper.readU16(buf)
            d.bigRebounds = wf.mspHelper.readU16(buf)
            d.meanRebound = readRatio(buf)
            d.meanOvershoot = readRatio(buf)
            d.meanCounter = readRatio(buf)
            d.meanIterm = readRatio(buf)
            callback(callbackParam, d)
        end,
        errorHandler = function(self)
            if errorCallback then errorCallback(callbackParam) end
        end,
        -- Roll of a real log: F hot (1.53x), 15% stop bounce-back
        simulatorResponse = { 1, 0, 147, 0, axis, 50, 0, 100, 0, 0, 0, 5, 70,
            211, 5, 250, 5, 202, 3, 90, 0,
            240, 5, 61, 5, 4, 6, 163, 0, 6, 4, 50, 0,
            216, 4, 129, 1, 4, 6, 251, 2, 194, 6, 100, 1,
            87, 0, 25, 0, 124, 1, 139, 1,
            35, 0, 18, 0, 150, 0, 190, 5, 20, 0, 3, 0 },
    }
    wf.mspQueue:add(message)
end

local function clear(callback, callbackParam)
    local message = {
        command = 0x5F19,
        payload = {},
        processReply = function(self, buf)
            if callback then callback(callbackParam) end
        end,
        simulatorResponse = {},
    }
    wf.mspQueue:add(message)
end

return {
    getAxis = getAxis,
    clear = clear,
}
