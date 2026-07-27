local function getDefaults()
    local defaults = {}
    defaults.batteryProfile = { min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } }
    return defaults
end

local function getBatteryProfile(callback, callbackParam, config)
    if not config then config = getDefaults() end
    local message = {
        command = 175, -- MSP_BATTERY_PROFILE, introduced in MSP API 12.9
        processReply = function(self, buf)
            config.batteryProfile.value = wf.mspHelper.readU8(buf)
            if callback then callback(callbackParam, config) end
        end,
        simulatorResponse = { 1 }
    }
    wf.mspQueue:add(message)
end

local function setBatteryProfile(config)
    local message = {
        command = 176, -- MSP_SET_BATTERY_PROFILE, introduced in MSP API 12.9
        payload = {},
        simulatorResponse = {}
    }
    wf.mspHelper.writeU8(message.payload, config.batteryProfile.value)
    wf.mspQueue:add(message)
end

return {
    read = getBatteryProfile,
    write = setBatteryProfile,
    getDefaults = getDefaults
}