-- MSP2_WING_TUNE_ADVISOR (0x5F18, read one axis) and MSP2_WING_TUNE_ADVISOR_CLEAR (0x5F19).
-- One axis per request. Layout: see wingflight-firmware src/main/msp/msp.c. Firmware without
-- them answers with an error.
--
-- Payload version 2 (48 bytes, one CRSF frame) packs each value into as few bytes as the
-- advice needs:
--   U8 version, U8 flags (bits 0-1 axis, bit 2 collecting), U16 seconds,
--   U32 P | F << 10 | B << 20, U8 relax, U8 rc rate,
--   U16 ffCount, U8 ffGain x64, S8 ffCorr x100, U8 ffLagMs,
--   3 + 3 x {U8 gain x64, U16 count} (setpoint, then throttle bands),
--   U16 fullCount, U16 fullSatCount, U8 fullRatio x100, U8 fullMaxRate in 10 deg/s,
--   U16 releases, U16 bigRebounds, U8 meanRebound x100, U8 meanOvershoot x64,
--   U8 meanCounter x100, S16 meanIterm x1000
-- Version 1 (65 bytes, snapshots 0.0.32 to 0.0.38) is still read: every value 16-bit, ratios
-- x1000. A reply of another version, or of another length than its version's, goes to the
-- error callback rather than being decoded into plausible wrong numbers.

local REPLY_BYTES = { [1] = 65, [2] = 48 }
local GAIN_SCALE = 64        -- ffGain, band gains, meanOvershoot
local CORR_SCALE = 100       -- ffCorr
local FRACTION_SCALE = 100   -- fullRatio, meanRebound, meanCounter
local RATE_STEP = 10         -- fullMaxRate, deg/s
local GAIN_BITS = 1024       -- P, F and B: 10 bits each of one U32

local function readRatio(buf)
    return wf.mspHelper.readS16(buf) / 1000
end

local function readGain(buf)
    return wf.mspHelper.readU8(buf) / GAIN_SCALE
end

local function readFraction(buf)
    return wf.mspHelper.readU8(buf) / FRACTION_SCALE
end

local function readBands(buf, read)
    local bands = {}
    for i = 1, 3 do
        bands[i] = { gain = read(buf), count = wf.mspHelper.readU16(buf) }
    end
    return bands
end

local function decodeV1(buf, d)
    local h = wf.mspHelper
    d.collecting = h.readU8(buf) ~= 0
    d.seconds = h.readU16(buf)
    d.axis = h.readU8(buf)
    d.P = h.readU16(buf)
    d.F = h.readU16(buf)
    d.B = h.readU16(buf)
    d.relax = h.readU8(buf)
    d.rcRate = h.readU8(buf)
    d.ffCount = h.readU16(buf)
    d.ffGain = readRatio(buf)
    d.ffCorr = readRatio(buf)
    d.ffLagMs = h.readU16(buf)
    d.spBands = readBands(buf, readRatio)
    d.thrBands = readBands(buf, readRatio)
    d.fullCount = h.readU16(buf)
    d.fullSatCount = h.readU16(buf)
    d.fullRatio = readRatio(buf)
    d.fullMaxRate = h.readU16(buf)
    d.releases = h.readU16(buf)
    d.bigRebounds = h.readU16(buf)
    d.meanRebound = readRatio(buf)
    d.meanOvershoot = readRatio(buf)
    d.meanCounter = readRatio(buf)
    d.meanIterm = readRatio(buf)
end

local function decodeV2(buf, d)
    local h = wf.mspHelper
    local flags = h.readU8(buf)
    d.collecting = math.floor(flags / 4) % 2 == 1
    d.seconds = h.readU16(buf)
    d.axis = flags % 4
    local gains = h.readU32(buf)
    d.P = gains % GAIN_BITS
    d.F = math.floor(gains / GAIN_BITS) % GAIN_BITS
    d.B = math.floor(gains / (GAIN_BITS * GAIN_BITS)) % GAIN_BITS
    d.relax = h.readU8(buf)
    d.rcRate = h.readU8(buf)
    d.ffCount = h.readU16(buf)
    d.ffGain = readGain(buf)
    d.ffCorr = h.readS8(buf) / CORR_SCALE
    d.ffLagMs = h.readU8(buf)
    d.spBands = readBands(buf, readGain)
    d.thrBands = readBands(buf, readGain)
    d.fullCount = h.readU16(buf)
    d.fullSatCount = h.readU16(buf)
    d.fullRatio = readFraction(buf)
    d.fullMaxRate = h.readU8(buf) * RATE_STEP
    d.releases = h.readU16(buf)
    d.bigRebounds = h.readU16(buf)
    d.meanRebound = readFraction(buf)
    d.meanOvershoot = readGain(buf)
    d.meanCounter = readFraction(buf)
    d.meanIterm = readRatio(buf)
end

-- axis: 0 roll, 1 pitch, 2 yaw
local function getAxis(axis, callback, callbackParam, errorCallback)
    local message = {
        command = 0x5F18,
        payload = { axis },
        processReply = function(self, buf)
            local version = buf[1]
            if REPLY_BYTES[version] == nil or #buf ~= REPLY_BYTES[version] then
                if errorCallback then errorCallback(callbackParam) end
                return
            end
            local d = {}
            d.version = wf.mspHelper.readU8(buf)
            if version == 1 then decodeV1(buf, d) else decodeV2(buf, d) end
            callback(callbackParam, d)
        end,
        errorHandler = function(self)
            if errorCallback then errorCallback(callbackParam) end
        end,
        -- Roll of a real log: F hot (1.53x), 15% stop bounce-back (payload version 2)
        simulatorResponse = { 2, axis, 147, 0, 50, 144, 1, 0, 5, 70,
            211, 5, 98, 97, 90,
            97, 61, 5, 99, 163, 0, 66, 50, 0,
            79, 129, 1, 99, 251, 2, 111, 100, 1,
            87, 0, 25, 0, 38, 40,
            35, 0, 18, 0, 15, 94, 2, 3, 0 },
    }
    wf.mspQueue:add(message)
end

local function clear(callback, callbackParam, errorCallback)
    local message = {
        command = 0x5F19,
        payload = {},
        processReply = function(self, buf)
            if callback then callback(callbackParam) end
        end,
        errorHandler = function(self)
            if errorCallback then errorCallback(callbackParam) end
        end,
        simulatorResponse = {},
    }
    wf.mspQueue:add(message)
end

return {
    getAxis = getAxis,
    clear = clear,
}
