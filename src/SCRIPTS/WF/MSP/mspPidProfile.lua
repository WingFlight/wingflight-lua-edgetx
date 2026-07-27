-- Several fields that used to be real heli-only settings are now wire-present-but-dead
-- placeholder bytes on this firmware (it always writes 0 -- or 1 for error_rotation -- and
-- discards whatever is written back); they are skip-read/written-as-filler here rather than
-- exposed as data, so downstream PAGES files must not reference them. A number of new
-- fixed-wing-only fields (fw_tpa_*, master_gain, autohover, cross_axis_relax, gain_curve,
-- atthold.max_rate) are appended at the end of the packet and are read/written here in full.

local function getDefaults()
    local data = {}
    data.pid_mode = { min = 0, max = 250 }
    data.iterm_decay_time = { min = 0, max = 250, scale = 10, unit = wf.units.seconds }
    data.iterm_decay_limit = { min = 0, max = 250, unit = wf.units.degreesPerSecond }
    if wf.apiVersion < 12.09 then
        data.error_rotation = { min = 0, max = 1, table = { [0] = "OFF", "ON" } }
    end
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
    data.angle_level_strength = { min = 25, max = 255 }
    data.angle_level_limit = { min = 10, max = 90, unit = wf.units.degrees }
    data.horizon_level_strength = { min = 0, max = 200 }
    data.trainer_gain = { min = 0, max = 250 }
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
    return data
end

local function getPidProfile(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 94, -- MSP_PID_PROFILE
        processReply = function(self, buf)
            data.pid_mode.value = wf.mspHelper.readU8(buf)
            buf.offset = buf.offset + 1 -- was error_decay_time_ground (dead)
            data.iterm_decay_time.value = wf.mspHelper.readU8(buf)
            buf.offset = buf.offset + 1 -- was error_decay_time_yaw (dead)
            data.iterm_decay_limit.value = wf.mspHelper.readU8(buf)
            buf.offset = buf.offset + 1 -- was error_decay_limit_yaw (dead)
            if wf.apiVersion < 12.09 then
                data.error_rotation.value = wf.mspHelper.readU8(buf)
            else
                buf.offset = buf.offset + 1 -- was error_rotation (dead, firmware always sends 1)
            end
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
            buf.offset = buf.offset + 5 -- was yaw_cw_stop_gain, yaw_ccw_stop_gain, yaw_precomp_cutoff, yaw_cyclic_ff_gain, yaw_collective_ff_gain (dead)
            buf.offset = buf.offset + 2 -- was yaw_collective_dynamic_gain, yaw_collective_dynamic_decay (dead)
            buf.offset = buf.offset + 1 -- was pitch_collective_ff_gain (dead)
            data.angle_level_strength.value = wf.mspHelper.readU8(buf)
            data.angle_level_limit.value = wf.mspHelper.readU8(buf)
            data.horizon_level_strength.value = wf.mspHelper.readU8(buf)
            data.trainer_gain.value = wf.mspHelper.readU8(buf)
            data.trainer_angle_limit.value = wf.mspHelper.readU8(buf)
            buf.offset = buf.offset + 3 -- was cyclic_cross_coupling_gain/ratio/cutoff (dead)
            data.atthold_gain.value = wf.mspHelper.readU8(buf)
            data.atthold_deadband.value = wf.mspHelper.readU8(buf)
            data.bterm_cutoff_roll.value = wf.mspHelper.readU8(buf)
            data.bterm_cutoff_pitch.value = wf.mspHelper.readU8(buf)
            data.bterm_cutoff_yaw.value = wf.mspHelper.readU8(buf)
            buf.offset = buf.offset + 2 -- was yaw_inertia_precomp_gain/cutoff (dead)
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
            callback(callbackParam, data)
        end,
        simulatorResponse = {
            3, 0, 25, 0, 250, 0, 1, 12, 0, 1, 30, 30, 45, 50, 50, 100, 15, 15, 20, 0, 0, 0, 0, 0, 0, 0, 0,
            2, 10, 10, 15, 100, 100, 0, 0, 0, 20, 25, 40, 55, 40, 0, 0,
            100, 0, 100, 0, 100, 0, 100, 0, 50, 30, 44, 1, 0, 30, 100, 10, 0, 0, 0, 0, 44, 1
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
    wf.mspHelper.writeU8(message.payload, 0) -- was error_decay_time_ground (dead)
    wf.mspHelper.writeU8(message.payload, data.iterm_decay_time.value)
    wf.mspHelper.writeU8(message.payload, 0) -- was error_decay_time_yaw (dead)
    wf.mspHelper.writeU8(message.payload, data.iterm_decay_limit.value)
    wf.mspHelper.writeU8(message.payload, 0) -- was error_decay_limit_yaw (dead)
    if wf.apiVersion < 12.09 then
        wf.mspHelper.writeU8(message.payload, data.error_rotation.value)
    else
        wf.mspHelper.writeU8(message.payload, 0) -- was error_rotation (dead)
    end
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
    for _ = 1, 5 do wf.mspHelper.writeU8(message.payload, 0) end -- was yaw_cw/ccw_stop_gain, yaw_precomp_cutoff, yaw_cyclic_ff_gain, yaw_collective_ff_gain (dead)
    wf.mspHelper.writeU8(message.payload, 0) -- was yaw_collective_dynamic_gain (dead)
    wf.mspHelper.writeU8(message.payload, 0) -- was yaw_collective_dynamic_decay (dead)
    wf.mspHelper.writeU8(message.payload, 0) -- was pitch_collective_ff_gain (dead)
    wf.mspHelper.writeU8(message.payload, data.angle_level_strength.value)
    wf.mspHelper.writeU8(message.payload, data.angle_level_limit.value)
    wf.mspHelper.writeU8(message.payload, data.horizon_level_strength.value)
    wf.mspHelper.writeU8(message.payload, data.trainer_gain.value)
    wf.mspHelper.writeU8(message.payload, data.trainer_angle_limit.value)
    for _ = 1, 3 do wf.mspHelper.writeU8(message.payload, 0) end -- was cyclic_cross_coupling_gain/ratio/cutoff (dead)
    wf.mspHelper.writeU8(message.payload, data.atthold_gain.value)
    wf.mspHelper.writeU8(message.payload, data.atthold_deadband.value)
    wf.mspHelper.writeU8(message.payload, data.bterm_cutoff_roll.value)
    wf.mspHelper.writeU8(message.payload, data.bterm_cutoff_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.bterm_cutoff_yaw.value)
    wf.mspHelper.writeU8(message.payload, 0) -- was yaw_inertia_precomp_gain (dead)
    wf.mspHelper.writeU8(message.payload, 0) -- was yaw_inertia_precomp_cutoff (dead)
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
    wf.mspQueue:add(message)
end

return {
    read = getPidProfile,
    write = setPidProfile,
    getDefaults = getDefaults
}
