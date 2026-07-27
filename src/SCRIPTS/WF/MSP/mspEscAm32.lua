local motorDirection = {
    [0] = "Normal",
    "Reversed",
}

local timingAdvance = {
    [0] = "0 " .. wf.units.degrees,
    "7.5 " .. wf.units.degrees,
    "15 " .. wf.units.degrees,
    "22.5 " .. wf.units.degrees,
}

local onOff = {
    [0] = "Off",
    "On",
}

local protocol = {
    [0] = "Auto",
    "DShot 300-600",
    "Servo 1-2ms",
    "Serial",
    "BF Safe Arming",
}

local brakeOnStop = {
    [0] = "Off",
    "Brake",
    "Active",
}

local variablePwm = {
    [0] = "Fixed",
    "Variable",
    "By RPM",
}

local lowVoltageCutoff = {
    [0] = "Off",
    "Cell based",
    "Absolute",
}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function normalizeTimingAdvance(raw)
    if raw == nil then return 0, "legacy" end
    if raw >= 10 and raw <= 42 then
        return clamp(math.floor((raw - 10) / 8 + 0.5), 0, 3), "new"
    end
    return clamp(math.floor(raw + 0.5), 0, 3), "legacy"
end

local function encodeTimingAdvance(value, encoding)
    value = clamp(math.floor((value or 0) + 0.5), 0, 3)
    if encoding == "new" then
        return 10 + value * 8
    end
    return value
end

local function normalizeMotorKv(raw)
    if raw == nil then return nil end
    return raw * 40 + 20
end

local function encodeMotorKv(value)
    if value == nil then return nil end
    return clamp(math.floor(((value - 20) / 40) + 0.5), 0, 255)
end

local function normalizeServoLow(raw)
    if raw == nil then return nil end
    return raw * 2 + 750
end

local function encodeServoLow(value)
    if value == nil then return nil end
    return clamp(math.floor(((value - 750) / 2) + 0.5), 0, 255)
end

local function normalizeServoHigh(raw)
    if raw == nil then return nil end
    return raw * 2 + 1750
end

local function encodeServoHigh(value)
    if value == nil then return nil end
    return clamp(math.floor(((value - 1750) / 2) + 0.5), 0, 255)
end

local function normalizeServoNeutral(raw)
    if raw == nil then return nil end
    return raw + 1374
end

local function encodeServoNeutral(value)
    if value == nil then return nil end
    return clamp(math.floor((value - 1374) + 0.5), 0, 255)
end

local function normalizeLowVoltageThreshold(raw)
    if raw == nil then return nil end
    return raw + 250
end

local function encodeLowVoltageThreshold(value)
    if value == nil then return nil end
    return clamp(math.floor((value - 250) + 0.5), 0, 255)
end

local function normalizeCurrentLimit(raw)
    if raw == nil then return nil end
    return raw * 2
end

local function encodeCurrentLimit(value)
    if value == nil then return nil end
    return clamp(math.floor((value / 2) + 0.5), 0, 255)
end

local function getFirmwareVersion(major, minor)
    if not(major and minor) then return "UNKNOWN" end
    return string.format("Firmware: %d.%d", major, minor)
end

local function getDefaults()
    local d = {}
    d.esc_signature = nil
    d.esc_command = nil
    d.reserved_0 = nil
    d.eeprom_version = nil
    d.reserved_1 = nil
    d.version_major = nil
    d.version_minor = nil
    d.max_ramp = nil
    d.minimum_duty_cycle = nil
    d.disable_stick_calibration = nil
    d.absolute_voltage_cutoff = nil
    d.current_p = nil
    d.current_i = nil
    d.current_d = nil
    d.active_brake_power = nil
    d.reserved_eeprom_3_0 = nil
    d.reserved_eeprom_3_1 = nil
    d.reserved_eeprom_3_2 = nil
    d.reserved_eeprom_3_3 = nil
    d.timing_advance_encoding = "legacy"
    d.motor_direction = { min = 0, max = #motorDirection, table = motorDirection }
    d.bidirectional_mode = { min = 0, max = #onOff, table = onOff }
    d.sinusoidal_startup = { min = 0, max = #onOff, table = onOff }
    d.complementary_pwm = { min = 0, max = #onOff, table = onOff }
    d.variable_pwm_frequency = { min = 0, max = #variablePwm, table = variablePwm }
    d.stuck_rotor_protection = { min = 0, max = #onOff, table = onOff }
    d.timing_advance = { min = 0, max = #timingAdvance, table = timingAdvance }
    d.pwm_frequency = { min = 8, max = 144, unit = wf.units.khz }
    d.startup_power = { min = 50, max = 150, unit = wf.units.percentage }
    d.motor_kv = { min = 20, max = 10220, unit = wf.units.kv }
    d.motor_poles = { min = 2, max = 36 }
    d.brake_on_stop = { min = 0, max = #brakeOnStop, table = brakeOnStop }
    d.stall_protection = { min = 0, max = #onOff, table = onOff }
    d.beep_volume = { min = 0, max = 11 }
    d.interval_telemetry = { min = 0, max = #onOff, table = onOff }
    d.servo_low_threshold = { min = 750, max = 1250 }
    d.servo_high_threshold = { min = 1750, max = 2250 }
    d.servo_neutral = { min = 1374, max = 1630 }
    d.servo_dead_band = { min = 0, max = 100 }
    d.low_voltage_cutoff = { min = 0, max = #lowVoltageCutoff, table = lowVoltageCutoff }
    d.low_voltage_threshold = { min = 250, max = 350, scale = 100, unit = wf.units.volt }
    d.rc_car_reversing = { min = 0, max = #onOff, table = onOff }
    d.use_hall_sensors = { min = 0, max = #onOff, table = onOff }
    d.sine_mode_range = { min = 5, max = 25 }
    d.brake_strength = { min = 0, max = 10 }
    d.running_brake_level = { min = 0, max = 10 }
    d.temperature_limit = { min = 70, max = 141, unit = wf.units.celsius }
    d.current_limit = { min = 0, max = 404 }
    d.sine_mode_power = { min = 1, max = 10 }
    d.esc_protocol = { min = 0, max = #protocol, table = protocol }
    d.auto_advance = { min = 0, max = #onOff, table = onOff }
    return d
end

local function getEscParameters(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 217, -- MSP_ESC_PARAMETERS,
        ignoreErrors = true,
        retryDelay = 1,
        processReply = function(self, buf)
            local signature = wf.mspHelper.readU8(buf)
            if signature ~= 194 then
                return
            end

            data.esc_signature = signature
            data.esc_command = wf.mspHelper.readU8(buf)
            data.reserved_0 = wf.mspHelper.readU8(buf)
            data.eeprom_version = wf.mspHelper.readU8(buf)
            data.reserved_1 = wf.mspHelper.readU8(buf)
            data.version_major = wf.mspHelper.readU8(buf)
            data.version_minor = wf.mspHelper.readU8(buf)
            data.max_ramp = wf.mspHelper.readU8(buf)
            data.minimum_duty_cycle = wf.mspHelper.readU8(buf)
            data.disable_stick_calibration = wf.mspHelper.readU8(buf)
            data.absolute_voltage_cutoff = wf.mspHelper.readU8(buf)
            data.current_p = wf.mspHelper.readU8(buf)
            data.current_i = wf.mspHelper.readU8(buf)
            data.current_d = wf.mspHelper.readU8(buf)
            data.active_brake_power = wf.mspHelper.readU8(buf)
            data.reserved_eeprom_3_0 = wf.mspHelper.readU8(buf)
            data.reserved_eeprom_3_1 = wf.mspHelper.readU8(buf)
            data.reserved_eeprom_3_2 = wf.mspHelper.readU8(buf)
            data.reserved_eeprom_3_3 = wf.mspHelper.readU8(buf)
            data.motor_direction.value = wf.mspHelper.readU8(buf)
            data.bidirectional_mode.value = wf.mspHelper.readU8(buf)
            data.sinusoidal_startup.value = wf.mspHelper.readU8(buf)
            data.complementary_pwm.value = wf.mspHelper.readU8(buf)
            data.variable_pwm_frequency.value = wf.mspHelper.readU8(buf)
            data.stuck_rotor_protection.value = wf.mspHelper.readU8(buf)

            local timingRaw = wf.mspHelper.readU8(buf)
            data.timing_advance.value, data.timing_advance_encoding = normalizeTimingAdvance(timingRaw)

            data.pwm_frequency.value = wf.mspHelper.readU8(buf)
            data.startup_power.value = wf.mspHelper.readU8(buf)
            data.motor_kv.value = normalizeMotorKv(wf.mspHelper.readU8(buf))
            data.motor_poles.value = wf.mspHelper.readU8(buf)
            data.brake_on_stop.value = wf.mspHelper.readU8(buf)
            data.stall_protection.value = wf.mspHelper.readU8(buf)
            data.beep_volume.value = wf.mspHelper.readU8(buf)
            data.interval_telemetry.value = wf.mspHelper.readU8(buf)
            data.servo_low_threshold.value = normalizeServoLow(wf.mspHelper.readU8(buf))
            data.servo_high_threshold.value = normalizeServoHigh(wf.mspHelper.readU8(buf))
            data.servo_neutral.value = normalizeServoNeutral(wf.mspHelper.readU8(buf))
            data.servo_dead_band.value = wf.mspHelper.readU8(buf)
            data.low_voltage_cutoff.value = wf.mspHelper.readU8(buf)
            data.low_voltage_threshold.value = normalizeLowVoltageThreshold(wf.mspHelper.readU8(buf))
            data.rc_car_reversing.value = wf.mspHelper.readU8(buf)
            data.use_hall_sensors.value = wf.mspHelper.readU8(buf)
            data.sine_mode_range.value = wf.mspHelper.readU8(buf)
            data.brake_strength.value = wf.mspHelper.readU8(buf)
            data.running_brake_level.value = wf.mspHelper.readU8(buf)
            data.temperature_limit.value = wf.mspHelper.readU8(buf)
            data.current_limit.value = normalizeCurrentLimit(wf.mspHelper.readU8(buf))
            data.sine_mode_power.value = wf.mspHelper.readU8(buf)
            data.esc_protocol.value = wf.mspHelper.readU8(buf)
            data.auto_advance.value = wf.mspHelper.readU8(buf)

            -- Derived fields
            data.firmwareVersion = getFirmwareVersion(data.version_major, data.version_minor)

            callback(callbackParam, data)
        end,
        simulatorResponse = { 194, 0, 1, 3, 1, 2, 19, 200, 2, 0, 10, 100, 0, 100, 0, 255, 255, 255, 255, 0, 0, 0, 0, 0, 1, 26, 16, 50, 12, 24, 0, 1, 5, 0, 128, 128, 128, 50, 0, 50, 0, 0, 10, 10, 10, 145, 102, 7, 1, 0 }
    }
    wf.mspQueue:add(message)
end

local function setEscParameters(data)
    local message = {
        command = 218, -- MSP_SET_ESC_PARAMETERS,
        retryDelay = 1,
        postSendDelay = 2,
        payload = {}
    }

    wf.mspHelper.writeU8(message.payload, data.esc_signature)
    wf.mspHelper.writeU8(message.payload, data.esc_command)
    wf.mspHelper.writeU8(message.payload, data.reserved_0)
    wf.mspHelper.writeU8(message.payload, data.eeprom_version)
    wf.mspHelper.writeU8(message.payload, data.reserved_1)
    wf.mspHelper.writeU8(message.payload, data.version_major)
    wf.mspHelper.writeU8(message.payload, data.version_minor)
    wf.mspHelper.writeU8(message.payload, data.max_ramp)
    wf.mspHelper.writeU8(message.payload, data.minimum_duty_cycle)
    wf.mspHelper.writeU8(message.payload, data.disable_stick_calibration)
    wf.mspHelper.writeU8(message.payload, data.absolute_voltage_cutoff)
    wf.mspHelper.writeU8(message.payload, data.current_p)
    wf.mspHelper.writeU8(message.payload, data.current_i)
    wf.mspHelper.writeU8(message.payload, data.current_d)
    wf.mspHelper.writeU8(message.payload, data.active_brake_power)
    wf.mspHelper.writeU8(message.payload, data.reserved_eeprom_3_0)
    wf.mspHelper.writeU8(message.payload, data.reserved_eeprom_3_1)
    wf.mspHelper.writeU8(message.payload, data.reserved_eeprom_3_2)
    wf.mspHelper.writeU8(message.payload, data.reserved_eeprom_3_3)
    wf.mspHelper.writeU8(message.payload, data.motor_direction.value)
    wf.mspHelper.writeU8(message.payload, data.bidirectional_mode.value)
    wf.mspHelper.writeU8(message.payload, data.sinusoidal_startup.value)
    wf.mspHelper.writeU8(message.payload, data.complementary_pwm.value)
    wf.mspHelper.writeU8(message.payload, data.variable_pwm_frequency.value)
    wf.mspHelper.writeU8(message.payload, data.stuck_rotor_protection.value)
    wf.mspHelper.writeU8(message.payload, encodeTimingAdvance(data.timing_advance.value, data.timing_advance_encoding))
    wf.mspHelper.writeU8(message.payload, data.pwm_frequency.value)
    wf.mspHelper.writeU8(message.payload, data.startup_power.value)
    wf.mspHelper.writeU8(message.payload, encodeMotorKv(data.motor_kv.value))
    wf.mspHelper.writeU8(message.payload, data.motor_poles.value)
    wf.mspHelper.writeU8(message.payload, data.brake_on_stop.value)
    wf.mspHelper.writeU8(message.payload, data.stall_protection.value)
    wf.mspHelper.writeU8(message.payload, data.beep_volume.value)
    wf.mspHelper.writeU8(message.payload, data.interval_telemetry.value)
    wf.mspHelper.writeU8(message.payload, encodeServoLow(data.servo_low_threshold.value))
    wf.mspHelper.writeU8(message.payload, encodeServoHigh(data.servo_high_threshold.value))
    wf.mspHelper.writeU8(message.payload, encodeServoNeutral(data.servo_neutral.value))
    wf.mspHelper.writeU8(message.payload, data.servo_dead_band.value)
    wf.mspHelper.writeU8(message.payload, data.low_voltage_cutoff.value)
    wf.mspHelper.writeU8(message.payload, encodeLowVoltageThreshold(data.low_voltage_threshold.value))
    wf.mspHelper.writeU8(message.payload, data.rc_car_reversing.value)
    wf.mspHelper.writeU8(message.payload, data.use_hall_sensors.value)
    wf.mspHelper.writeU8(message.payload, data.sine_mode_range.value)
    wf.mspHelper.writeU8(message.payload, data.brake_strength.value)
    wf.mspHelper.writeU8(message.payload, data.running_brake_level.value)
    wf.mspHelper.writeU8(message.payload, data.temperature_limit.value)
    wf.mspHelper.writeU8(message.payload, encodeCurrentLimit(data.current_limit.value))
    wf.mspHelper.writeU8(message.payload, data.sine_mode_power.value)
    wf.mspHelper.writeU8(message.payload, data.esc_protocol.value)
    wf.mspHelper.writeU8(message.payload, data.auto_advance.value)

    wf.mspQueue:add(message)
end

return {
    read = getEscParameters,
    write = setEscParameters,
    getDefaults = getDefaults
}
