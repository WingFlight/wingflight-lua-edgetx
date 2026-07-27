local function getDefaults()
    local defaults = {}
    defaults.rates_type = {}
    defaults.roll_rcRates = {}
    defaults.roll_rcExpo = {}
    defaults.roll_rates = {}

    defaults.pitch_rcRates = {}
    defaults.pitch_rcExpo = {}
    defaults.pitch_rates = {}

    defaults.yaw_rcRates = {}
    defaults.yaw_rcExpo = {}
    defaults.yaw_rates = {}

    defaults.collective_rcRates = {}
    defaults.collective_rcExpo = {}
    defaults.collective_rates = {}

    defaults.roll_response_time = { min = 0, max = 250 }
    defaults.roll_accel_limit = { min = 0, max = 50000, scale = 0.1 }
    defaults.pitch_response_time = { min = 0, max = 250 }
    defaults.pitch_accel_limit = { min = 0, max = 50000, scale = 0.1 }
    defaults.yaw_response_time = { min = 0, max = 250 }
    defaults.yaw_accel_limit = { min = 0, max = 50000, scale = 0.1 }
    defaults.collective_response_time = { min = 0, max = 250 }
    defaults.collective_accel_limit = { min = 0, max = 50000, scale = 0.1 }

    if wf.apiVersion >= 12.08 then
        defaults.roll_setpoint_boost_gain = { min = 0, max = 250 }
        defaults.roll_setpoint_boost_cutoff = { min = 0, max = 250, unit = wf.units.herz }
        defaults.pitch_setpoint_boost_gain = { min = 0, max = 250 }
        defaults.pitch_setpoint_boost_cutoff = { min = 0, max = 250, unit = wf.units.herz }
        defaults.yaw_setpoint_boost_gain = { min = 0, max = 250 }
        defaults.yaw_setpoint_boost_cutoff = { min = 0, max = 250, unit = wf.units.herz }
        defaults.collective_setpoint_boost_gain = { min = 0, max = 250 }
        defaults.collective_setpoint_boost_cutoff = { min = 0, max = 250, unit = wf.units.herz }
        defaults.yaw_dynamic_ceiling_gain = { min = 0, max = 250 }
        defaults.yaw_dynamic_deadband_gain = { min = 0, max = 250 }
        defaults.yaw_dynamic_deadband_filter = { min = 0, max = 250, scale = 10, unit = wf.units.herz }
    end

    if wf.apiVersion >= 12.09 then
        defaults.cyclic_ring = { min = 0, max = 250, unit = wf.units.percentage }
        defaults.cyclic_polar = { min = 0, max = 1, table = { [0] = "Off", "On" } }
    end

    defaults.columnHeaders = { "", "", "", "", "", "" }

    return defaults
end

local function getRateDefaults(data, rates_type)
    data.rates_type = { value = rates_type, min = 0, table = { [0] = "NONE", "BETAFL", "RACEFL", "KISS", "ACTUAL", "QUICK" } }
    if wf.apiVersion >= 12.09 then
        data.rates_type.table[#data.rates_type.table + 1] = "WINGFL"
    end
    data.rates_type.max = #data.rates_type.table
    local rateName = data.rates_type.table[rates_type]
    --wf.print("rateName: " .. rateName)
    local setRateDefaults = wf.executeScript("MSP/RATES/" .. rateName)
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
            local rates_type = wf.mspHelper.readU8(buf)
            local data = getRateDefaults(data, rates_type)
            data.rates_type.value = rates_type
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
            data.collective_rcRates.value = wf.mspHelper.readU8(buf)
            data.collective_rcExpo.value = wf.mspHelper.readU8(buf)
            data.collective_rates.value = wf.mspHelper.readU8(buf)
            data.collective_response_time.value = wf.mspHelper.readU8(buf)
            data.collective_accel_limit.value = wf.mspHelper.readU16(buf)
            if wf.apiVersion >= 12.08 then
                data.roll_setpoint_boost_gain.value = wf.mspHelper.readU8(buf)
                data.roll_setpoint_boost_cutoff.value = wf.mspHelper.readU8(buf)
                data.pitch_setpoint_boost_gain.value = wf.mspHelper.readU8(buf)
                data.pitch_setpoint_boost_cutoff.value = wf.mspHelper.readU8(buf)
                data.yaw_setpoint_boost_gain.value = wf.mspHelper.readU8(buf)
                data.yaw_setpoint_boost_cutoff.value = wf.mspHelper.readU8(buf)
                data.collective_setpoint_boost_gain.value = wf.mspHelper.readU8(buf)
                data.collective_setpoint_boost_cutoff.value = wf.mspHelper.readU8(buf)
                data.yaw_dynamic_ceiling_gain.value = wf.mspHelper.readU8(buf)
                data.yaw_dynamic_deadband_gain.value = wf.mspHelper.readU8(buf)
                data.yaw_dynamic_deadband_filter.value = wf.mspHelper.readU8(buf)
            end
            if wf.apiVersion >= 12.09 then
                data.cyclic_ring.value = wf.mspHelper.readU8(buf)
                data.cyclic_polar.value = wf.mspHelper.readU8(buf)
            end
            callback(callbackParam, data)
        end,
        simulatorResponse = { 6, 50, 40, 24, 0, 0, 0, 50, 40, 24, 0, 0, 0, 80, 50, 24, 0, 0, 0, 100, 0, 24, 0, 0, 0, 0, 15, 0, 15, 0, 90, 0, 15, 30, 30, 60, 0 }
    }
    wf.mspQueue:add(message)
end

local function setRcTuning(data)
    local message = {
        command = 204, -- MSP_SET_RC_TUNING
        payload = {},
        simulatorResponse = {}
    }
    wf.mspHelper.writeU8(message.payload, data.rates_type.value)
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
    wf.mspHelper.writeU8(message.payload, data.collective_rcRates.value)
    wf.mspHelper.writeU8(message.payload, data.collective_rcExpo.value)
    wf.mspHelper.writeU8(message.payload, data.collective_rates.value)
    wf.mspHelper.writeU8(message.payload, data.collective_response_time.value)
    wf.mspHelper.writeU16(message.payload, data.collective_accel_limit.value)
    if wf.apiVersion >= 12.08 then
        wf.mspHelper.writeU8(message.payload, data.roll_setpoint_boost_gain.value)
        wf.mspHelper.writeU8(message.payload, data.roll_setpoint_boost_cutoff.value)
        wf.mspHelper.writeU8(message.payload, data.pitch_setpoint_boost_gain.value)
        wf.mspHelper.writeU8(message.payload, data.pitch_setpoint_boost_cutoff.value)
        wf.mspHelper.writeU8(message.payload, data.yaw_setpoint_boost_gain.value)
        wf.mspHelper.writeU8(message.payload, data.yaw_setpoint_boost_cutoff.value)
        wf.mspHelper.writeU8(message.payload, data.collective_setpoint_boost_gain.value)
        wf.mspHelper.writeU8(message.payload, data.collective_setpoint_boost_cutoff.value)
        wf.mspHelper.writeU8(message.payload, data.yaw_dynamic_ceiling_gain.value)
        wf.mspHelper.writeU8(message.payload, data.yaw_dynamic_deadband_gain.value)
        wf.mspHelper.writeU8(message.payload, data.yaw_dynamic_deadband_filter.value)
    end
    if wf.apiVersion >= 12.09 then
        wf.mspHelper.writeU8(message.payload, data.cyclic_ring.value)
        wf.mspHelper.writeU8(message.payload, data.cyclic_polar.value)
    end
    wf.mspQueue:add(message)
end

return {
    read = getRcTuning,
    write = setRcTuning,
    getDefaults = getDefaults,
    getRateDefaults = getRateDefaults,
}