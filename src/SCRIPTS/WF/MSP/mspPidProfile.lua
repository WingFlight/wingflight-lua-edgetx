-- MSP_PID_PROFILE / MSP_SET_PID_PROFILE: verified against Wingflight msp.c.
-- The 51-byte base is followed by 5 reserved bytes (1 + 4, Auto Hover until 22.11),
-- then API 22.4 axis limits (4), then API 22.10 GPS speed attenuation (4),
-- then API 22.13 Angle mode damping (1), then snap relax (6), then prop-hang relax (4).
-- Only write extensions received from the FC.
local axisLimits = {
    {key = "angle_roll_limit", shared = "angle_level_limit", max = 90},
    {key = "angle_pitch_limit", shared = "angle_level_limit", max = 75},
    {key = "trainer_roll_limit", shared = "trainer_angle_limit", max = 90},
    {key = "trainer_pitch_limit", shared = "trainer_angle_limit", max = 75},
}

local function getDefaults()
    local data = {}
    data.pid_mode = { min = 0, max = 250 }
    data.iterm_decay_time_roll = { min = 1, max = 100, scale = 100, unit = wf.units.seconds }
    data.iterm_decay_time_pitch = { min = 1, max = 100, scale = 100, unit = wf.units.seconds }
    data.iterm_decay_time_yaw = { min = 1, max = 100, scale = 100, unit = wf.units.seconds }
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
    data.iterm_relax_level_roll = { min = 10, max = 250, unit = wf.units.degreesPerSecond }
    data.iterm_relax_level_pitch = { min = 10, max = 250, unit = wf.units.degreesPerSecond }
    data.iterm_relax_level_yaw = { min = 10, max = 250, unit = wf.units.degreesPerSecond }
    data.bounceback_roll = { min = 1, max = 10 }
    data.bounceback_pitch = { min = 1, max = 10 }
    data.bounceback_yaw = { min = 1, max = 10 }
    data.angle_level_strength = { min = 0, max = 200 }
    data.angle_level_limit = { min = 10, max = 90, unit = wf.units.degrees }
    data.trainer_gain = { min = 25, max = 255 }
    data.trainer_angle_limit = { min = 10, max = 80, unit = wf.units.degrees }
    data.atthold_gain = { min = 0, max = 250 }
    data.atthold_deadband = { min = 0, max = 100, unit = wf.units.percentage }
    data.bterm_cutoff_roll = { min = 0, max = 250, unit = wf.units.herz }
    data.bterm_cutoff_pitch = { min = 0, max = 250, unit = wf.units.herz }
    data.bterm_cutoff_yaw = { min = 0, max = 250, unit = wf.units.herz }
    data.fw_tpa_gain = { min = 25, max = 200, unit = wf.units.percentage }
    data.fw_tpa_curve = { min = 0, max = 8 }
    data.master_gain_roll = { min = 0, max = 200, unit = wf.units.percentage }
    data.master_gain_pitch = { min = 0, max = 200, unit = wf.units.percentage }
    data.master_gain_yaw = { min = 0, max = 200, unit = wf.units.percentage }
    data.cross_axis_relax_strength = { min = 0, max = 100, unit = wf.units.percentage }
    data.cross_axis_relax_level = { min = 10, max = 250 }
    data.cross_axis_relax_cutoff = { min = 1, max = 100, unit = wf.units.herz }
    data.cross_axis_relax_pitch_strength = { min = 0, max = 100, unit = wf.units.percentage }
    data.gain_curve_roll = { min = 0, max = 8 }
    data.gain_curve_pitch = { min = 0, max = 8 }
    data.gain_curve_yaw = { min = 0, max = 8 }
    data.atthold_max_rate = { min = 0, max = 1800, unit = wf.units.degreesPerSecond }
    data.fw_spa_gain = { min = 25, max = 200, unit = wf.units.percentage }
    data.fw_spa_curve = { min = 0, max = 8 }
    data.fw_spa_speed_max = { min = 10, max = 600, unit = "km/h" }
    data.angle_level_damping = { min = 0, max = 100, unit = wf.units.percentage }
    data.snap_relax_strength = { min = 0, max = 100, unit = wf.units.percentage }
    data.snap_relax_threshold = { min = 20, max = 100, unit = wf.units.percentage }
    data.snap_relax_window = { min = 0, max = 1000, unit = "ms" }
    data.snap_relax_hold = { min = 0, max = 1000, unit = "ms" }
    data.prop_hang_strength = { min = 0, max = 100, unit = wf.units.percentage }
    data.prop_hang_angle = { min = 5, max = 45, unit = wf.units.degrees }
    data.prop_hang_fade = { min = 0, max = 2000, unit = "ms" }
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
            data.iterm_decay_time_roll.value = wf.mspHelper.readU8(buf)
            data.iterm_decay_time_pitch.value = wf.mspHelper.readU8(buf)
            data.iterm_decay_time_yaw.value = wf.mspHelper.readU8(buf)
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
            data.iterm_relax_level_roll.value = wf.mspHelper.readU8(buf)
            data.iterm_relax_level_pitch.value = wf.mspHelper.readU8(buf)
            data.iterm_relax_level_yaw.value = wf.mspHelper.readU8(buf)
            data.bounceback_roll.value = wf.mspHelper.readU8(buf)
            data.bounceback_pitch.value = wf.mspHelper.readU8(buf)
            data.bounceback_yaw.value = wf.mspHelper.readU8(buf)
            data.angle_level_strength.value = wf.mspHelper.readU8(buf)
            data.angle_level_limit.value = wf.mspHelper.readU8(buf)
            -- reserved, was Horizon level strength (removed in API 22.12)
            wf.mspHelper.readU8(buf)
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
            -- reserved, was Auto Hover gain/max angle/max rate (removed in API 22.11)
            wf.mspHelper.readU8(buf)
            wf.mspHelper.readU8(buf)
            wf.mspHelper.readU16(buf)
            data.cross_axis_relax_strength.value = wf.mspHelper.readU8(buf)
            data.cross_axis_relax_level.value = wf.mspHelper.readU8(buf)
            data.cross_axis_relax_cutoff.value = wf.mspHelper.readU8(buf)
            data.cross_axis_relax_pitch_strength.value = wf.mspHelper.readU8(buf)
            data.gain_curve_roll.value = wf.mspHelper.readU8(buf)
            data.gain_curve_pitch.value = wf.mspHelper.readU8(buf)
            data.gain_curve_yaw.value = wf.mspHelper.readU8(buf)
            data.atthold_max_rate.value = wf.mspHelper.readU16(buf)
            data.has_roll_deadband = #buf >= 52
            data.has_throttle_assist = #buf >= 56
            data.has_axis_limits = #buf >= 60
            data.has_fw_spa = #buf >= 64
            data.has_level_damping = #buf >= 65
            data.has_snap_relax = #buf >= 71
            data.has_prop_hang = #buf >= 75
            -- reserved, was Auto Hover roll deadband and throttle assist
            if data.has_roll_deadband then
                wf.mspHelper.readU8(buf)
            end
            if data.has_throttle_assist then
                wf.mspHelper.readU8(buf)
                wf.mspHelper.readU8(buf)
                wf.mspHelper.readU16(buf)
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
            data.fw_spa_gain.value = nil
            data.fw_spa_curve.value = nil
            data.fw_spa_speed_max.value = nil
            if data.has_fw_spa then
                data.fw_spa_gain.value = wf.mspHelper.readU8(buf)
                data.fw_spa_curve.value = wf.mspHelper.readU8(buf)
                data.fw_spa_speed_max.value = wf.mspHelper.readU16(buf)
            end
            data.angle_level_damping.value = nil
            if data.has_level_damping then
                data.angle_level_damping.value = wf.mspHelper.readU8(buf)
            end
            data.snap_relax_strength.value = nil
            data.snap_relax_threshold.value = nil
            data.snap_relax_window.value = nil
            data.snap_relax_hold.value = nil
            if data.has_snap_relax then
                data.snap_relax_strength.value = wf.mspHelper.readU8(buf)
                data.snap_relax_threshold.value = wf.mspHelper.readU8(buf)
                data.snap_relax_window.value = wf.mspHelper.readU16(buf)
                data.snap_relax_hold.value = wf.mspHelper.readU16(buf)
            end
            data.prop_hang_strength.value = nil
            data.prop_hang_angle.value = nil
            data.prop_hang_fade.value = nil
            if data.has_prop_hang then
                data.prop_hang_strength.value = wf.mspHelper.readU8(buf)
                data.prop_hang_angle.value = wf.mspHelper.readU8(buf)
                data.prop_hang_fade.value = wf.mspHelper.readU16(buf)
            end
            callback(callbackParam, data)
        end,
        simulatorResponse = {
            1, 60, 60, 60, 35,              -- pid mode, I-term decay time, limit
            45, 45, 60,                     -- error limit
            50, 50, 100, 15, 15, 20,        -- gyro, D-term cutoffs
            22, 22, 22, 5, 5, 5,            -- I-term relax level, bounceback
            40, 55, 0,                      -- angle strength, limit, reserved
            75, 20, 40, 5,                  -- trainer gain, limit, atthold gain, deadband
            15, 15, 20, 100, 0,             -- B-term cutoffs, TPA gain, curve
            100, 0, 100, 0, 100, 0,         -- master gains
            0, 0, 0, 0,                     -- reserved
            0, 100, 10, 0,                  -- cross-axis relax
            0, 0, 0, 44, 1,                 -- gain curves, atthold max rate
            0, 0, 0, 0, 0,                  -- reserved
            0, 0, 0, 0,                     -- axis limits (inherit)
            100, 0, 150, 0,                 -- SPA gain, curve, speed max
            25,                             -- angle damping
            100, 60, 144, 1, 94, 1,         -- snap relax strength, threshold, window, hold (350 ms)
            100, 20, 244, 1                 -- prop-hang relax strength, angle, fade (500 ms)
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
    wf.mspHelper.writeU8(message.payload, data.iterm_decay_time_roll.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_decay_time_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_decay_time_yaw.value)
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
    wf.mspHelper.writeU8(message.payload, data.iterm_relax_level_roll.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_relax_level_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.iterm_relax_level_yaw.value)
    wf.mspHelper.writeU8(message.payload, data.bounceback_roll.value)
    wf.mspHelper.writeU8(message.payload, data.bounceback_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.bounceback_yaw.value)
    wf.mspHelper.writeU8(message.payload, data.angle_level_strength.value)
    wf.mspHelper.writeU8(message.payload, data.angle_level_limit.value)
    wf.mspHelper.writeU8(message.payload, 0) -- reserved, was Horizon level strength
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
    wf.mspHelper.writeU8(message.payload, 0)  -- reserved, was Auto Hover gain
    wf.mspHelper.writeU8(message.payload, 0)  -- reserved, was Auto Hover max angle
    wf.mspHelper.writeU16(message.payload, 0) -- reserved, was Auto Hover max rate
    wf.mspHelper.writeU8(message.payload, data.cross_axis_relax_strength.value)
    wf.mspHelper.writeU8(message.payload, data.cross_axis_relax_level.value)
    wf.mspHelper.writeU8(message.payload, data.cross_axis_relax_cutoff.value)
    wf.mspHelper.writeU8(message.payload, data.cross_axis_relax_pitch_strength.value)
    wf.mspHelper.writeU8(message.payload, data.gain_curve_roll.value)
    wf.mspHelper.writeU8(message.payload, data.gain_curve_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.gain_curve_yaw.value)
    wf.mspHelper.writeU16(message.payload, data.atthold_max_rate.value)
    if data.has_roll_deadband then
        wf.mspHelper.writeU8(message.payload, 0) -- reserved, was Auto Hover roll deadband
    end
    if data.has_throttle_assist then
        -- reserved, was Auto Hover throttle assist gain/max/trigger
        wf.mspHelper.writeU8(message.payload, 0)
        wf.mspHelper.writeU8(message.payload, 0)
        wf.mspHelper.writeU16(message.payload, 0)
    end
    if data.has_axis_limits then
        for _, limit in ipairs(axisLimits) do
            local field = data[limit.key]
            local value = field.value == field.initial and field.raw or math.max(10, math.min(limit.max, field.value))
            wf.mspHelper.writeU8(message.payload, value)
        end
    end
    if data.has_axis_limits and data.has_fw_spa then
        wf.mspHelper.writeU8(message.payload, data.fw_spa_gain.value)
        wf.mspHelper.writeU8(message.payload, data.fw_spa_curve.value)
        wf.mspHelper.writeU16(message.payload, data.fw_spa_speed_max.value)
    end
    if data.has_axis_limits and data.has_fw_spa and data.has_level_damping then
        wf.mspHelper.writeU8(message.payload, data.angle_level_damping.value)
    end
    if data.has_axis_limits and data.has_fw_spa and data.has_level_damping and data.has_snap_relax then
        wf.mspHelper.writeU8(message.payload, data.snap_relax_strength.value)
        wf.mspHelper.writeU8(message.payload, data.snap_relax_threshold.value)
        wf.mspHelper.writeU16(message.payload, data.snap_relax_window.value)
        wf.mspHelper.writeU16(message.payload, data.snap_relax_hold.value)
    end
    if data.has_axis_limits and data.has_fw_spa and data.has_level_damping and data.has_snap_relax and data.has_prop_hang then
        wf.mspHelper.writeU8(message.payload, data.prop_hang_strength.value)
        wf.mspHelper.writeU8(message.payload, data.prop_hang_angle.value)
        wf.mspHelper.writeU16(message.payload, data.prop_hang_fade.value)
    end
    wf.mspQueue:add(message)
end

return {
    read = getPidProfile,
    write = setPidProfile,
    getDefaults = getDefaults
}
