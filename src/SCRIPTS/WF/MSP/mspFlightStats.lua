local function getDefaults()
    local defaults = {}
    defaults.stats_total_flights = { min = 0, max = 2147483647 } -- Actual max is 4294967295, but EdgeTX doesn't support unsigned longs.
    defaults.stats_total_time_s = { min = 0, max = 2147483647, unit = wf.units.seconds }
    defaults.stats_total_dist_m = { min = 0, max = 2147483647, unit = wf.units.meters }
    defaults.stats_min_armed_time_s = { min = -1, max = 127, unit = wf.units.seconds }
    -- Calculated fields
    defaults.statsEnabled = { min = 0, max = 1, table = { [0] = "Off", "On" } }
    return defaults
end

local function getFlightStats(callback, callbackParam, config)
    if not config then config = getDefaults() end
    local message = {
        command = 14, -- MSP_FLIGHT_STATS, introduced in MSP API 12.9
        processReply = function(self, buf)
            config.stats_total_flights.value = wf.mspHelper.readU32(buf)
            config.stats_total_time_s.value = wf.mspHelper.readU32(buf)
            config.stats_total_dist_m.value = wf.mspHelper.readU32(buf)
            config.stats_min_armed_time_s.value = wf.mspHelper.readS8(buf)
            -- Calculated fields
            config.statsEnabled.value = config.stats_min_armed_time_s.value ~= -1 and 1 or 0
            if callback then callback(callbackParam, config) end
        end,
        simulatorResponse = { 123,1,0,0, 100,1,2,0, 0,0,0,0, 15}
    }
    wf.mspQueue:add(message)
end

local function setFlightStats(config)
    local message = {
        command = 15, -- MSP_SET_FLIGHT_STATS, introduced in MSP API 12.9
        payload = {},
        simulatorResponse = {}
    }
    wf.mspHelper.writeU32(message.payload, config.stats_total_flights.value)
    wf.mspHelper.writeU32(message.payload, config.stats_total_time_s.value)
    wf.mspHelper.writeU32(message.payload, config.stats_total_dist_m.value)
    wf.mspHelper.writeU8(message.payload, config.stats_min_armed_time_s.value)
    wf.mspQueue:add(message)
end

return {
    read = getFlightStats,
    write = setFlightStats,
    getDefaults = getDefaults
}