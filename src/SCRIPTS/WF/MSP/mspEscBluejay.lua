local onOff = {
    [0] = "Off",
    "On",
}

local motorDirection = {
    [0] = "Normal",
    "Reversed",
    "Forward/Reverse (3D)",
    "Forward/Reverse (3D) Rev",
}

local commutationTiming = {
    [0] = "Low",
    "Medium Low",
    "Medium",
    "Medium High",
    "High",
}

local demagCompensation = {
    [0] = "Off",
    "Low",
    "High",
}

local beaconDelay = {
    [0] = "1 minute",
    "2 minutes",
    "5 minutes",
    "10 minutes",
    "Infinite",
}

local temperatureProtection = {
    [0] = "Disabled",
    "80 C",
    "90 C",
    "100 C",
    "110 C",
    "120 C",
    "130 C",
    "140 C",
}

local rampupPower = {
    [0] = "Off",
    "1x (More protection)",
    "2x",
    "3x",
    "4x",
    "5x",
    "6x",
    "7x",
    "8x",
    "9x",
    "10x",
    "11x",
    "12x",
    "13x (Less protection)"
}

local edtOnOff = {
    [100] = "Off",
    [1] = "On",
}

local powerRating = { [0] = "1S", "2S+"}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function getFirmwareVersion(major, minor)
    if not(major and minor) then return "UNKNOWN" end
    return string.format("Firmware: %d.%d", major, minor)
end

local function normalizeStartupPowerMin(raw)
    if raw == nil then return nil end
    return math.floor((raw * 1000 / 2047) + 1000 + 0.5)
end

local function encodeStartupPowerMin(value)
    if value == nil then return nil end
    return clamp(math.floor(((value - 1000) * 2047) / 1000 + 0.5), 0, 255)
end

local function normalizeStartupPowerMax(raw)
    if raw == nil then return nil end
    return math.floor((raw * 1000 / 250) + 1000 + 0.5)
end

local function encodeStartupPowerMax(value)
    if value == nil then return nil end
    return clamp(math.floor(((value - 1000) * 250) / 1000 + 0.5), 0, 255)
end

local function getDefaults()
    local d = {}
	d.esc_signature = nil
	d.esc_command = nil
	d.main_revision = nil
	d.sub_revision = nil
	d.layout_revision = nil
	d.reserved_03 = nil
	d.startup_power_min = { min = 1000, max = 1125, mult = 5 }
	d.startup_beep = nil
	d.dithering = nil
	d.startup_power_max = { min = 1004, max = 1300, mult = 4 }
	d.reserved_08 = nil
	d.rpm_power_slope = { min = 0, max = 255, table = rampupPower }
	d.pwm_frequency = nil
	d.motor_direction = { min = 0, max = #motorDirection, table = motorDirection }
	d.reserved_0c = nil
	d.mode_raw = nil
	d.reserved_0f = nil
	d.breaking_strength = { min = 0, max = 255 }
	d.reserved_11_14 = nil
	d.commutation_timing = { min = 0, max = #commutationTiming, table = commutationTiming }
	d.reserved_16_19 = nil
	d.reserved_1a = nil
	d.beep_strength = { min = 1, max = 255 }
	d.beacon_strength = { min = 1, max = 255 }
	d.beacon_delay = { min = 0, max = #beaconDelay, table = beaconDelay }
	d.reserved_1e = nil
	d.demag_compensation = { min = 0, max = #demagCompensation, table = demagCompensation }
	d.reserved_20_21 = nil
	d.reserved_22 = nil
	d.temperature_protection = { min = 0, max = #temperatureProtection, table = temperatureProtection }
	d.low_rpm_power_protection = { min = 0, max = #onOff, table = onOff }
	d.reserved_25_26 = nil
	d.brake_on_stop = { min = 0, max = #onOff, table = onOff }
	d.led_control = nil
	d.power_rating = { min = 0, max = #powerRating, table = powerRating }
	d.force_edt_arm = { min = 0, max = #onOff, table = edtOnOff }
	d.reserved_2b = nil
	d.reserved_2c_2f = nil
	d.reserved_30_33 = nil
	d.reserved_34_37 = nil
	d.reserved_38_3b = nil
	d.reserved_3c_3f = nil
    return d
end

local function getEscParameters(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 217, -- MSP_ESC_PARAMETERS
        ignoreErrors = true, -- it usually works after a few errors (?)
        retryDelay = 0, -- fast retry
        processReply = function(self, buf)
            local signature = wf.mspHelper.readU8(buf)
            if signature ~= 193 then
                return
            end

            data.esc_signature = signature
            data.esc_command = wf.mspHelper.readU8(buf)
            data.main_revision = wf.mspHelper.readU8(buf)
            if data.main_revision ~= 0 then
                return
            end
            data.sub_revision = wf.mspHelper.readU8(buf)
            data.layout_revision = wf.mspHelper.readU8(buf)
            data.reserved_03 = wf.mspHelper.readU8(buf)
            data.startup_power_min.value = normalizeStartupPowerMin(wf.mspHelper.readU8(buf))
            data.startup_beep = wf.mspHelper.readU8(buf)
            data.dithering = wf.mspHelper.readU8(buf)
            data.startup_power_max.value = normalizeStartupPowerMax(wf.mspHelper.readU8(buf))
            data.reserved_08 = wf.mspHelper.readU8(buf)
            data.rpm_power_slope.value = wf.mspHelper.readU8(buf)
            data.pwm_frequency = wf.mspHelper.readU8(buf)
            data.motor_direction.value = wf.mspHelper.readU8(buf) - 1
            data.reserved_0c = wf.mspHelper.readU8(buf)
            data.mode_raw = wf.mspHelper.readU16(buf)
            data.reserved_0f = wf.mspHelper.readU8(buf)
            data.breaking_strength.value = wf.mspHelper.readU8(buf)
            data.reserved_11_14 = wf.mspHelper.readU32(buf)
            data.commutation_timing.value = wf.mspHelper.readU8(buf) - 1
            data.reserved_16_19 = wf.mspHelper.readU32(buf)
            data.reserved_1a = wf.mspHelper.readU8(buf)
            data.beep_strength.value = wf.mspHelper.readU8(buf)
            data.beacon_strength.value = wf.mspHelper.readU8(buf)
            data.beacon_delay.value = wf.mspHelper.readU8(buf) - 1
            data.reserved_1e = wf.mspHelper.readU8(buf)
            data.demag_compensation.value = wf.mspHelper.readU8(buf) - 1
            data.reserved_20_21 = wf.mspHelper.readU16(buf)
            data.reserved_22 = wf.mspHelper.readU8(buf)
            data.temperature_protection.value = wf.mspHelper.readU8(buf)
            data.low_rpm_power_protection.value = wf.mspHelper.readU8(buf) - 1
            data.reserved_25_26 = wf.mspHelper.readU16(buf)
            data.brake_on_stop.value = wf.mspHelper.readU8(buf)
            data.led_control = wf.mspHelper.readU8(buf)
            data.power_rating.value = wf.mspHelper.readU8(buf) - 1
            data.force_edt_arm.value = wf.mspHelper.readU8(buf)
            data.reserved_2b = wf.mspHelper.readU8(buf)
            data.reserved_2c_2f = wf.mspHelper.readU32(buf)
            data.reserved_30_33 = wf.mspHelper.readU32(buf)
            data.reserved_34_37 = wf.mspHelper.readU32(buf)
            data.reserved_38_3b = wf.mspHelper.readU32(buf)
            data.reserved_3c_3f = wf.mspHelper.readU32(buf)

            -- Derived fields
            data.firmwareVersion = getFirmwareVersion(data.main_revision, data.sub_revision)

            callback(callbackParam, data)
        end,

        simulatorResponse = { 193, 0, 0, 21, 208, 255, 102, 1, 255, 50, 255, 9, 24, 2, 255, 85, 170, 255, 0, 255, 255, 255, 255, 4, 255, 255, 255, 255, 255, 40, 80, 4, 255, 2, 255, 255, 255, 0, 255, 255, 255, 0, 0, 2, 100, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
        --simulatorResponseBluejay022 = { 193, 0, 0, 22, 209, 255, 51, 0, 0, 5, 255, 9, 24, 1, 255, 85, 170, 255, 255, 255, 255, 255, 255, 4, 255, 255, 255, 255, 255, 40, 80, 4, 255, 2, 255, 255, 255, 0, 1, 255, 255, 0, 0, 2, 0, 170, 85, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    }
    wf.mspQueue:add(message)
end

local function setEscParameters(data)
    local message = {
        command = 218, -- MSP_SET_ESC_PARAMETERS
        retryDelay = 1,
        postSendDelay = 2,
        payload = {}
    }

    wf.mspHelper.writeU8(message.payload, data.esc_signature)
    wf.mspHelper.writeU8(message.payload, data.esc_command)
    wf.mspHelper.writeU8(message.payload, data.main_revision)
    wf.mspHelper.writeU8(message.payload, data.sub_revision)
    wf.mspHelper.writeU8(message.payload, data.layout_revision)
    wf.mspHelper.writeU8(message.payload, data.reserved_03)
    wf.mspHelper.writeU8(message.payload, encodeStartupPowerMin(data.startup_power_min.value))
    wf.mspHelper.writeU8(message.payload, data.startup_beep)
    wf.mspHelper.writeU8(message.payload, data.dithering)
    wf.mspHelper.writeU8(message.payload, encodeStartupPowerMax(data.startup_power_max.value))
    wf.mspHelper.writeU8(message.payload, data.reserved_08)
    wf.mspHelper.writeU8(message.payload, data.rpm_power_slope.value)
    wf.mspHelper.writeU8(message.payload, data.pwm_frequency)
    wf.mspHelper.writeU8(message.payload, data.motor_direction.value + 1)
    wf.mspHelper.writeU8(message.payload, data.reserved_0c)
    wf.mspHelper.writeU16(message.payload, data.mode_raw)
    wf.mspHelper.writeU8(message.payload, data.reserved_0f)
    wf.mspHelper.writeU8(message.payload, data.breaking_strength.value)
    wf.mspHelper.writeU32(message.payload, data.reserved_11_14)
    wf.mspHelper.writeU8(message.payload, data.commutation_timing.value + 1)
    wf.mspHelper.writeU32(message.payload, data.reserved_16_19)
    wf.mspHelper.writeU8(message.payload, data.reserved_1a)
    wf.mspHelper.writeU8(message.payload, data.beep_strength.value)
    wf.mspHelper.writeU8(message.payload, data.beacon_strength.value)
    wf.mspHelper.writeU8(message.payload, data.beacon_delay.value + 1)
    wf.mspHelper.writeU8(message.payload, data.reserved_1e)
    wf.mspHelper.writeU8(message.payload, data.demag_compensation.value + 1)
    wf.mspHelper.writeU16(message.payload, data.reserved_20_21)
    wf.mspHelper.writeU8(message.payload, data.reserved_22)
    wf.mspHelper.writeU8(message.payload, data.temperature_protection.value)
    wf.mspHelper.writeU8(message.payload, data.low_rpm_power_protection.value)
    wf.mspHelper.writeU16(message.payload, data.reserved_25_26)
    wf.mspHelper.writeU8(message.payload, data.brake_on_stop.value)
    wf.mspHelper.writeU8(message.payload, data.led_control)
    wf.mspHelper.writeU8(message.payload, data.power_rating.value + 1)
    wf.mspHelper.writeU8(message.payload, data.force_edt_arm.value)
    wf.mspHelper.writeU8(message.payload, data.reserved_2b)
    wf.mspHelper.writeU32(message.payload, data.reserved_2c_2f)
    wf.mspHelper.writeU32(message.payload, data.reserved_30_33)
    wf.mspHelper.writeU32(message.payload, data.reserved_34_37)
    wf.mspHelper.writeU32(message.payload, data.reserved_38_3b)
    wf.mspHelper.writeU32(message.payload, data.reserved_3c_3f)

    wf.mspQueue:add(message)
end

return {
    read = getEscParameters,
    write = setEscParameters,
    getDefaults = getDefaults
}









