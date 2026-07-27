local function getDefaults()
    local defaults = {}
    if wf.apiVersion < 12.09 then
        defaults.batteryCapacity = { min = 0, max = 20000, mult = 25, unit = wf.units.mah }
    end
    defaults.batteryCellCount = { min = 0, max = 24 }
    defaults.voltageMeterSource = { min = 0, max = 3, table = { [0] = "None", "ADC", "ESC" } }
    defaults.currentMeterSource = { min = 0, max = 3, table = { [0] = "None", "ADC", "ESC" } }
    defaults.vbatmincellvoltage = { min = 100, max = 500, scale = 100, unit =  wf.units.volt }
    defaults.vbatmaxcellvoltage = { min = 100, max = 500, scale = 100, unit =  wf.units.volt }
    defaults.vbatfullcellvoltage = { min = 100, max = 500, scale = 100, unit =  wf.units.volt }
    defaults.vbatwarningcellvoltage = { min = 100, max = 500, scale = 100, unit =  wf.units.volt }
    defaults.lvcPercentage = { min = 0, max = 100, unit = wf.units.percentage }
    defaults.consumptionWarningPercentage = { min = 0, max = 100, unit = wf.units.percentage }
    if wf.apiVersion >= 12.09 then
        defaults.batteryCapacity = { }
        for i = 0, 5 do
            defaults.batteryCapacity[i] = { min = 0, max = 20000, mult = 25, units = wf.units.mah }
        end
    end

    return defaults
end

local function getBatteryConfig(callback, callbackParam, config)
    if not config then config = getDefaults() end
    local message = {
        command = 32, -- MSP_BATTERY_CONFIG
        processReply = function(self, buf)
            local activeBatteryCapacity =  wf.mspHelper.readU16(buf)
            if wf.apiVersion < 12.09 then
                config.batteryCapacity.value = activeBatteryCapacity
            end
            config.batteryCellCount.value = wf.mspHelper.readU8(buf)
            config.voltageMeterSource.value = wf.mspHelper.readU8(buf)
            config.currentMeterSource.value = wf.mspHelper.readU8(buf)
            config.vbatmincellvoltage.value = wf.mspHelper.readU16(buf)
            config.vbatmaxcellvoltage.value = wf.mspHelper.readU16(buf)
            config.vbatfullcellvoltage.value = wf.mspHelper.readU16(buf)
            config.vbatwarningcellvoltage.value = wf.mspHelper.readU16(buf)
            config.lvcPercentage.value = wf.mspHelper.readU8(buf)
            config.consumptionWarningPercentage.value = wf.mspHelper.readU8(buf)
            if wf.apiVersion >= 12.09 then
                for i = 0, 5 do
                    config.batteryCapacity[i].value = wf.mspHelper.readU16(buf)
                end
            end
            if callback then callback(callbackParam, config) end
        end,
        simulatorResponse = { 184, 11, 12, 2, 2, 64, 1, 174, 1, 154, 1, 94, 1, 100, 10, 152, 8, 184, 11, 172, 13, 160, 15, 0, 0, 0, 0 }
    }
    wf.mspQueue:add(message)
end

local function setBatteryConfig(config)
    local message = {
        command = 33, -- MSP_SET_BATTERY_CONFIG
        payload = {},
        simulatorResponse = {}
    }
    if wf.apiVersion < 12.09 then
        wf.mspHelper.writeU16(message.payload, config.batteryCapacity.value)
    else
        wf.mspHelper.writeU16(message.payload, config.batteryCapacity[0].value) -- will be overwritten later
    end
    wf.mspHelper.writeU8(message.payload, config.batteryCellCount.value)
    wf.mspHelper.writeU8(message.payload, config.voltageMeterSource .value)
    wf.mspHelper.writeU8(message.payload, config.currentMeterSource .value)
    wf.mspHelper.writeU16(message.payload, config.vbatmincellvoltage .value)
    wf.mspHelper.writeU16(message.payload, config.vbatmaxcellvoltage .value)
    wf.mspHelper.writeU16(message.payload, config.vbatfullcellvoltage .value)
    wf.mspHelper.writeU16(message.payload, config.vbatwarningcellvoltage .value)
    wf.mspHelper.writeU8(message.payload, config.lvcPercentage .value)
    wf.mspHelper.writeU8(message.payload, config.consumptionWarningPercentage .value)
    if wf.apiVersion >= 12.09 then
        for i = 0, 5 do
            wf.mspHelper.writeU16(message.payload, config.batteryCapacity[i].value)
        end
    end

    wf.mspQueue:add(message)
end

return {
    read = getBatteryConfig,
    write = setBatteryConfig,
    getDefaults = getDefaults
}