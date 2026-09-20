-- WINGFL is the one rate-curve flavor whose metadata matches this firmware's fixed formula,
-- so it is always loaded; there is no rates_type selection anymore.

local function getDefaults()
    local defaults = {}
    defaults.roll_rcRates = {}
    defaults.roll_rcExpo = {}
    defaults.roll_rates = {}

    defaults.pitch_rcRates = {}
    defaults.pitch_rcExpo = {}
    defaults.pitch_rates = {}

    defaults.yaw_rcRates = {}
    defaults.yaw_rcExpo = {}
    defaults.yaw_rates = {}

    defaults.roll_response_time = { min = 0, max = 250 }
    defaults.roll_accel_limit = { min = 0, max = 50000, scale = 0.1 }
    defaults.pitch_response_time = { min = 0, max = 250 }
    defaults.pitch_accel_limit = { min = 0, max = 50000, scale = 0.1 }
    defaults.yaw_response_time = { min = 0, max = 250 }
    defaults.yaw_accel_limit = { min = 0, max = 50000, scale = 0.1 }

    defaults.roll_setpoint_boost_gain = { min = 0, max = 250 }
    defaults.roll_setpoint_boost_cutoff = { min = 0, max = 250, unit = wf.units.herz }
    defaults.pitch_setpoint_boost_gain = { min = 0, max = 250 }
    defaults.pitch_setpoint_boost_cutoff = { min = 0, max = 250, unit = wf.units.herz }
    defaults.yaw_setpoint_boost_gain = { min = 0, max = 250 }
    defaults.yaw_setpoint_boost_cutoff = { min = 0, max = 250, unit = wf.units.herz }
    defaults.yaw_dynamic_ceiling_gain = { min = 0, max = 250 }
    defaults.yaw_dynamic_deadband_gain = { min = 0, max = 250 }
    defaults.yaw_dynamic_deadband_filter = { min = 0, max = 250, scale = 10, unit = wf.units.herz }

    defaults.columnHeaders = { "", "", "", "", "", "" }

    return defaults
end

local function getRateDefaults(data)
    local setRateDefaults = wf.executeScript("MSP/RATES/WINGFL")
    setRateDefaults(data)
    setRateDefaults = nil
    collectgarbage()
    return data
end

local function getRcTuning(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 111, -- MSP_RC_TUNING
        processReply = function(self, buf)
            data = getRateDefaults(data)
            data.roll_rcRates.value = wf.mspHelper.readU8(buf)
            data.roll_rcExpo.value = wf.mspHelper.readU8(buf)
            data.roll_rates.value = wf.mspHelper.readU8(buf)
            data.roll_response_time.value = wf.mspHelper.readU8(buf)
            data.roll_accel_limit.value = wf.mspHelper.readU16(buf)
            data.pitch_rcRates.value = wf.mspHelper.readU8(buf)
            data.pitch_rcExpo.value = wf.mspHelper.readU8(buf)
            data.pitch_rates.value = wf.mspHelper.readU8(buf)
            data.pitch_response_time.value = wf.mspHelper.readU8(buf)
            data.pitch_accel_limit.value = wf.mspHelper.readU16(buf)
            data.yaw_rcRates.value = wf.mspHelper.readU8(buf)
            data.yaw_rcExpo.value = wf.mspHelper.readU8(buf)
            data.yaw_rates.value = wf.mspHelper.readU8(buf)
            data.yaw_response_time.value = wf.mspHelper.readU8(buf)
            data.yaw_accel_limit.value = wf.mspHelper.readU16(buf)
            data.roll_setpoint_boost_gain.value = wf.mspHelper.readU8(buf)
            data.roll_setpoint_boost_cutoff.value = wf.mspHelper.readU8(buf)
            data.pitch_setpoint_boost_gain.value = wf.mspHelper.readU8(buf)
            data.pitch_setpoint_boost_cutoff.value = wf.mspHelper.readU8(buf)
            data.yaw_setpoint_boost_gain.value = wf.mspHelper.readU8(buf)
            data.yaw_setpoint_boost_cutoff.value = wf.mspHelper.readU8(buf)
            data.yaw_dynamic_ceiling_gain.value = wf.mspHelper.readU8(buf)
            data.yaw_dynamic_deadband_gain.value = wf.mspHelper.readU8(buf)
            data.yaw_dynamic_deadband_filter.value = wf.mspHelper.readU8(buf)
            callback(callbackParam, data)
        end,
        simulatorResponse = { 50, 40, 24, 0, 0, 0, 50, 40, 24, 0, 0, 0, 80, 50, 24, 0, 0, 0, 0, 15, 0, 15, 0, 90, 0, 10, 60 }
    }
    wf.mspQueue:add(message)
end

local function setRcTuning(data)
    local message = {
        command = 204, -- MSP_SET_RC_TUNING
        payload = {},
        simulatorResponse = {}
    }
    wf.mspHelper.writeU8(message.payload, data.roll_rcRates.value)
    wf.mspHelper.writeU8(message.payload, data.roll_rcExpo.value)
    wf.mspHelper.writeU8(message.payload, data.roll_rates.value)
    wf.mspHelper.writeU8(message.payload, data.roll_response_time.value)
    wf.mspHelper.writeU16(message.payload, data.roll_accel_limit.value)
    wf.mspHelper.writeU8(message.payload, data.pitch_rcRates.value)
    wf.mspHelper.writeU8(message.payload, data.pitch_rcExpo.value)
    wf.mspHelper.writeU8(message.payload, data.pitch_rates.value)
    wf.mspHelper.writeU8(message.payload, data.pitch_response_time.value)
    wf.mspHelper.writeU16(message.payload, data.pitch_accel_limit.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_rcRates.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_rcExpo.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_rates.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_response_time.value)
    wf.mspHelper.writeU16(message.payload, data.yaw_accel_limit.value)
    wf.mspHelper.writeU8(message.payload, data.roll_setpoint_boost_gain.value)
    wf.mspHelper.writeU8(message.payload, data.roll_setpoint_boost_cutoff.value)
    wf.mspHelper.writeU8(message.payload, data.pitch_setpoint_boost_gain.value)
    wf.mspHelper.writeU8(message.payload, data.pitch_setpoint_boost_cutoff.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_setpoint_boost_gain.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_setpoint_boost_cutoff.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_dynamic_ceiling_gain.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_dynamic_deadband_gain.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_dynamic_deadband_filter.value)
    wf.mspQueue:add(message)
end

return {
    read = getRcTuning,
    write = setRcTuning,
    getDefaults = getDefaults,
    getRateDefaults = getRateDefaults,
}
