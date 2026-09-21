-- MSP_PID_PROFILE / MSP_SET_PID_PROFILE: verified against Wingflight msp.c.
-- The 47-byte base is followed by roll deadband (1), throttle assist (4),
-- then API 22.4 axis limits (4). Only write extensions received from the FC.
local axisLimits = {
    {key = "angle_roll_limit", shared = "angle_level_limit", max = 90},
    {key = "angle_pitch_limit", shared = "angle_level_limit", max = 75},
    {key = "trainer_roll_limit", shared = "trainer_angle_limit", max = 90},
    {key = "trainer_pitch_limit", shared = "trainer_angle_limit", max = 75},
}

local function getDefaults()
    local data = {}
    data.pid_mode = { min = 0, max = 250 }
    data.iterm_decay_time = { min = 0, max = 250, scale = 10, unit = wf.units.seconds }
    data.iterm_decay_limit = { min = 0, max = 250, unit = wf.units.degreesPerSecond }
    data.error_limit_roll = { min = 0, max = 180, unit = wf.units.degrees }
    data.error_limit_pitch = { min = 0, max = 180, unit = wf.units.degrees }
    data.error_limit_yaw = { min = 0, max = 180, unit = wf.units.degrees }
    data.gyro_cutoff_roll = { min = 0, max = 250, unit = wf.units.herz }
    data.gyro_cutoff_pitch = { min = 0, max = 250, unit = wf.units.herz }
    data.gyro_cutoff_yaw = { min = 0, max = 250, unit = wf.units.herz }
    data.dterm_cutoff_roll = { min = 0, max = 250, unit = wf.units.herz }
    data.dterm_cutoff_pitch = { min = 0, max = 250, unit = wf.units.herz }
    data.dterm_cutoff_yaw = { min = 0, max = 250, unit = wf.units.herz }
    data.iterm_relax_type = { min = 0, max = 2, table = { [0] = "OFF", "RP", "RPY" } }
    data.iterm_relax_cutoff_roll = { min = 1, max = 100, unit = wf.units.herz }
    data.iterm_relax_cutoff_pitch = { min = 1, max = 100, unit = wf.units.herz }
    data.iterm_relax_cutoff_yaw = { min = 1, max = 100, unit = wf.units.herz }
    data.angle_level_strength = { min = 0, max = 200 }
    data.angle_level_limit = { min = 10, max = 90, unit = wf.units.degrees }
    data.horizon_level_strength = { min = 0, max = 200 }
    data.trainer_gain = { min = 25, max = 255 }
    data.trainer_angle_limit = { min = 10, max = 80, unit = wf.units.degrees }
    data.atthold_gain = { min = 0, max = 250 }
    data.atthold_deadband = { min = 0, max = 100, unit = wf.units.percentage }
    data.bterm_cutoff_roll = { min = 0, max = 250, unit = wf.units.herz }
    data.bterm_cutoff_pitch = { min = 0, max = 250, unit = wf.units.herz }
    data.bterm_cutoff_yaw = { min = 0, max = 250, unit = wf.units.herz }
    data.fw_tpa_gain = { min = 25, max = 200, unit = wf.units.percentage }
    data.fw_tpa_curve = { min = 0, max = 8 }
    data.master_gain_roll = { min = 25, max = 1000, unit = wf.units.percentage }
    data.master_gain_pitch = { min = 25, max = 1000, unit = wf.units.percentage }
    data.master_gain_yaw = { min = 25, max = 1000, unit = wf.units.percentage }
    data.autohover_gain = { min = 0, max = 250 }
    data.autohover_max_angle = { min = 0, max = 90, unit = wf.units.degrees }
    data.autohover_max_rate = { min = 0, max = 1800, unit = wf.units.degreesPerSecond }
    data.cross_axis_relax_strength = { min = 0, max = 100, unit = wf.units.percentage }
    data.cross_axis_relax_level = { min = 10, max = 250 }
    data.cross_axis_relax_cutoff = { min = 1, max = 100, unit = wf.units.herz }
    data.cross_axis_relax_pitch_strength = { min = 0, max = 100, unit = wf.units.percentage }
    data.gain_curve_roll = { min = 0, max = 8 }
    data.gain_curve_pitch = { min = 0, max = 8 }
    data.gain_curve_yaw = { min = 0, max = 8 }
    data.atthold_max_rate = { min = 0, max = 1800, unit = wf.units.degreesPerSecond }
    data.autohover_roll_deadband = { min = 0, max = 100, unit = wf.units.percentage }
    data.autohover_throttle_assist_gain = { min = 0, max = 100, unit = wf.units.percentage }
    data.autohover_throttle_assist_max = { min = 0, max = 50, unit = wf.units.percentage }
    data.autohover_throttle_assist_trigger_ms = { min = 0, max = 2000, unit = "ms" }
    for _, limit in ipairs(axisLimits) do
        data[limit.key] = { min = 10, max = limit.max, unit = wf.units.degrees }
    end
    return data
end

local function getPidProfile(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 94, -- MSP_PID_PROFILE
        processReply = function(self, buf)
            data.pid_mode.value = wf.mspHelper.readU8(buf)
            data.iterm_decay_time.value = wf.mspHelper.readU8(buf)
            data.iterm_decay_limit.value = wf.mspHelper.readU8(buf)
            data.error_limit_roll.value = wf.mspHelper.readU8(buf)
            data.error_limit_pitch.value = wf.mspHelper.readU8(buf)
            data.error_limit_yaw.value = wf.mspHelper.readU8(buf)
            data.gyro_cutoff_roll.value = wf.mspHelper.readU8(buf)
            data.gyro_cutoff_pitch.value = wf.mspHelper.readU8(buf)
            data.gyro_cutoff_yaw.value = wf.mspHelper.readU8(buf)
            data.dterm_cutoff_roll.value = wf.mspHelper.readU8(buf)
            data.dterm_cutoff_pitch.value = wf.mspHelper.readU8(buf)
            data.dterm_cutoff_yaw.value = wf.mspHelper.readU8(buf)
            data.iterm_relax_type.value = wf.mspHelper.readU8(buf)
            data.iterm_relax_cutoff_roll.value = wf.mspHelper.readU8(buf)
            data.iterm_relax_cutoff_pitch.value = wf.mspHelper.readU8(buf)
            data.iterm_relax_cutoff_yaw.value = wf.mspHelper.readU8(buf)
            data.angle_level_strength.value = wf.mspHelper.readU8(buf)
            data.angle_level_limit.value = wf.mspHelper.readU8(buf)
            data.horizon_level_strength.value = wf.mspHelper.readU8(buf)
            data.trainer_gain.value = wf.mspHelper.readU8(buf)
            data.trainer_angle_limit.value = wf.mspHelper.readU8(buf)
            data.atthold_gain.value = wf.mspHelper.readU8(buf)
            data.atthold_deadband.value = wf.mspHelper.readU8(buf)
            data.bterm_cutoff_roll.value = wf.mspHelper.readU8(buf)
            data.bterm_cutoff_pitch.value = wf.mspHelper.readU8(buf)
            data.bterm_cutoff_yaw.value = wf.mspHelper.readU8(buf)
            data.fw_tpa_gain.value = wf.mspHelper.readU8(buf)
            data.fw_tpa_curve.value = wf.mspHelper.readU8(buf)
            data.master_gain_roll.value = wf.mspHelper.readU16(buf)
            data.master_gain_pitch.value = wf.mspHelper.readU16(buf)
            data.master_gain_yaw.value = wf.mspHelper.readU16(buf)
            data.autohover_gain.value = wf.mspHelper.readU8(buf)
            data.autohover_max_angle.value = wf.mspHelper.readU8(buf)
            data.autohover_max_rate.value = wf.mspHelper.readU16(buf)
            data.cross_axis_relax_strength.value = wf.mspHelper.readU8(buf)
            data.cross_axis_relax_level.value = wf.mspHelper.readU8(buf)
            data.cross_axis_relax_cutoff.value = wf.mspHelper.readU8(buf)
            data.cross_axis_relax_pitch_strength.value = wf.mspHelper.readU8(buf)
            data.gain_curve_roll.value = wf.mspHelper.readU8(buf)
            data.gain_curve_pitch.value = wf.mspHelper.readU8(buf)
            data.gain_curve_yaw.value = wf.mspHelper.readU8(buf)
            data.atthold_max_rate.value = wf.mspHelper.readU16(buf)
            data.has_roll_deadband = #buf >= 48
            data.has_throttle_assist = #buf >= 52
            data.has_axis_limits = #buf >= 56
            data.autohover_roll_deadband.value = data.has_roll_deadband and wf.mspHelper.readU8(buf) or nil
            data.autohover_throttle_assist_gain.value = nil
            data.autohover_throttle_assist_max.value = nil
            data.autohover_throttle_assist_trigger_ms.value = nil
            if data.has_throttle_assist then
                data.autohover_throttle_assist_gain.value = wf.mspHelper.readU8(buf)
                data.autohover_throttle_assist_max.value = wf.mspHelper.readU8(buf)
                data.autohover_throttle_assist_trigger_ms.value = wf.mspHelper.readU16(buf)
            end
            for _, limit in ipairs(axisLimits) do
                local field = data[limit.key]
                field.value, field.raw, field.initial = nil, nil, nil
                field.max = limit.max
                if data.has_axis_limits then
                    field.raw = wf.mspHelper.readU8(buf)
                    -- Zero inherits the old shared limit. Preserve it on unrelated saves,
                    -- including legacy pitch limits above the new explicit 75-degree cap.
                    field.value = field.raw == 0 and data[limit.shared].value or field.raw
                    field.initial = field.value
                    field.max = math.max(limit.max, field.value)
                end
            end
            callback(callbackParam, data)
        end,
        simulatorResponse = {
            3, 25, 250,
            30, 30, 45, 50, 50, 100, 15, 15, 20,
            2, 10, 10, 15,
            50, 55, 40, 80, 40,
            50, 10,
            20, 25, 40,
            100, 0,
            100, 0, 100, 0, 100, 0,
            50, 30, 44, 1,
            0, 100, 10, 0,
            0, 0, 0,
            44, 1,
            5, 0, 15, 44, 1,
            0, 0, 0, 0
        },
    }
    wf.mspQueue:add(message)
end

local function setPidProfile(data)
    local message = {
        command = 95, -- MSP_SET_PID_PROFILE
        payload = {},
        simulatorResponse = {}
    }
    wf.mspHelper.writeU8(message.payload, data.pid_mode.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_decay_time.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_decay_limit.value)
    wf.mspHelper.writeU8(message.payload, data.error_limit_roll.value)
    wf.mspHelper.writeU8(message.payload, data.error_limit_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.error_limit_yaw.value)
    wf.mspHelper.writeU8(message.payload, data.gyro_cutoff_roll.value)
    wf.mspHelper.writeU8(message.payload, data.gyro_cutoff_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.gyro_cutoff_yaw.value)
    wf.mspHelper.writeU8(message.payload, data.dterm_cutoff_roll.value)
    wf.mspHelper.writeU8(message.payload, data.dterm_cutoff_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.dterm_cutoff_yaw.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_relax_type.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_relax_cutoff_roll.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_relax_cutoff_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_relax_cutoff_yaw.value)
    wf.mspHelper.writeU8(message.payload, data.angle_level_strength.value)
    wf.mspHelper.writeU8(message.payload, data.angle_level_limit.value)
    wf.mspHelper.writeU8(message.payload, data.horizon_level_strength.value)
    wf.mspHelper.writeU8(message.payload, data.trainer_gain.value)
    wf.mspHelper.writeU8(message.payload, data.trainer_angle_limit.value)
    wf.mspHelper.writeU8(message.payload, data.atthold_gain.value)
    wf.mspHelper.writeU8(message.payload, data.atthold_deadband.value)
    wf.mspHelper.writeU8(message.payload, data.bterm_cutoff_roll.value)
    wf.mspHelper.writeU8(message.payload, data.bterm_cutoff_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.bterm_cutoff_yaw.value)
    wf.mspHelper.writeU8(message.payload, data.fw_tpa_gain.value)
    wf.mspHelper.writeU8(message.payload, data.fw_tpa_curve.value)
    wf.mspHelper.writeU16(message.payload, data.master_gain_roll.value)
    wf.mspHelper.writeU16(message.payload, data.master_gain_pitch.value)
    wf.mspHelper.writeU16(message.payload, data.master_gain_yaw.value)
    wf.mspHelper.writeU8(message.payload, data.autohover_gain.value)
    wf.mspHelper.writeU8(message.payload, data.autohover_max_angle.value)
    wf.mspHelper.writeU16(message.payload, data.autohover_max_rate.value)
    wf.mspHelper.writeU8(message.payload, data.cross_axis_relax_strength.value)
    wf.mspHelper.writeU8(message.payload, data.cross_axis_relax_level.value)
    wf.mspHelper.writeU8(message.payload, data.cross_axis_relax_cutoff.value)
    wf.mspHelper.writeU8(message.payload, data.cross_axis_relax_pitch_strength.value)
    wf.mspHelper.writeU8(message.payload, data.gain_curve_roll.value)
    wf.mspHelper.writeU8(message.payload, data.gain_curve_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.gain_curve_yaw.value)
    wf.mspHelper.writeU16(message.payload, data.atthold_max_rate.value)
    if data.has_roll_deadband then
        wf.mspHelper.writeU8(message.payload, data.autohover_roll_deadband.value)
    end
    if data.has_throttle_assist then
        wf.mspHelper.writeU8(message.payload, data.autohover_throttle_assist_gain.value)
        wf.mspHelper.writeU8(message.payload, data.autohover_throttle_assist_max.value)
        wf.mspHelper.writeU16(message.payload, data.autohover_throttle_assist_trigger_ms.value)
    end
    if data.has_axis_limits then
        for _, limit in ipairs(axisLimits) do
            local field = data[limit.key]
            local value = field.value == field.initial and field.raw or math.max(10, math.min(limit.max, field.value))
            wf.mspHelper.writeU8(message.payload, value)
        end
    end
    wf.mspQueue:add(message)
end

return {
    read = getPidProfile,
    write = setPidProfile,
    getDefaults = getDefaults
}
