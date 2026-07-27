local function getDefaults()
    local data = {}
    data.pid_mode = { min = 0, max = 250 }
    data.error_decay_time_ground = { min = 0, max = 250, scale = 10, unit = wf.units.seconds }
    data.error_decay_time_cyclic = { min = 0, max = 250, scale = 10, unit = wf.units.seconds }
    data.error_decay_time_yaw = { min = 0, max = 250, scale = 10, unit = wf.units.seconds }
    data.error_decay_limit_cyclic = { min = 0, max = 250, unit = wf.units.degreesPerSecond }
    data.error_decay_limit_yaw = { min = 0, max = 250, unit = wf.units.degreesPerSecond }
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
    data.yaw_cw_stop_gain = { min = 25, max = 250 }
    data.yaw_ccw_stop_gain = { min = 25, max = 250 }
    data.yaw_precomp_cutoff = { min = 0, max = 250, unit = wf.units.herz }
    data.yaw_cyclic_ff_gain = { min = 0, max = 250 }
    data.yaw_collective_ff_gain = { min = 0, max = 250 }
    if wf.apiVersion < 12.08 then
        data.yaw_collective_dynamic_gain = { min = 0, max = 250 }
        data.yaw_collective_dynamic_decay = { min = 0, max = 250 }
    end
    data.pitch_collective_ff_gain = { min = 0, max = 250 }
    data.angle_level_strength = { min = 25, max = 255 }
    data.angle_level_limit = { min = 10, max = 90, unit = wf.units.degrees }
    data.horizon_level_strength = { min = 0, max = 200 }
    data.trainer_gain = { min = 0, max = 250 }
    data.trainer_angle_limit = { min = 10, max = 80, unit = wf.units.degrees }
    data.cyclic_cross_coupling_gain =  { min = 0, max = 250 }
    data.cyclic_cross_coupling_ratio =  { min = 0, max = 200, unit = wf.units.percentage }
    data.cyclic_cross_coupling_cutoff =  { min = 1, max = 250, scale = 10, unit = wf.units.herz }
    data.offset_limit_roll = { min = 0, max = 180, unit = wf.units.degrees }
    data.offset_limit_pitch = { min = 0, max = 180, unit = wf.units.degrees }
    data.bterm_cutoff_roll = { min = 0, max = 250, unit = wf.units.herz }
    data.bterm_cutoff_pitch = { min = 0, max = 250, unit = wf.units.herz }
    data.bterm_cutoff_yaw = { min = 0, max = 250, unit = wf.units.herz }
    if wf.apiVersion >= 12.08 then
        data.yaw_inertia_precomp_gain = { min = 0, max = 250 }
        data.yaw_inertia_precomp_cutoff = { min = 0, max = 250, scale = 10, unit = wf.units.herz }
    end
    return data
end

local function getPidProfile(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 94, -- MSP_PID_PROFILE
        processReply = function(self, buf)
            data.pid_mode.value = wf.mspHelper.readU8(buf)
            data.error_decay_time_ground.value = wf.mspHelper.readU8(buf)
            data.error_decay_time_cyclic.value = wf.mspHelper.readU8(buf)
            data.error_decay_time_yaw.value = wf.mspHelper.readU8(buf)
            data.error_decay_limit_cyclic.value = wf.mspHelper.readU8(buf)
            data.error_decay_limit_yaw.value = wf.mspHelper.readU8(buf)
            if wf.apiVersion < 12.09 then
                data.error_rotation.value = wf.mspHelper.readU8(buf)
            else
                buf.offset = buf.offset + 1
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
            data.yaw_cw_stop_gain.value = wf.mspHelper.readU8(buf)
            data.yaw_ccw_stop_gain.value = wf.mspHelper.readU8(buf)
            data.yaw_precomp_cutoff.value = wf.mspHelper.readU8(buf)
            data.yaw_cyclic_ff_gain.value = wf.mspHelper.readU8(buf)
            data.yaw_collective_ff_gain.value = wf.mspHelper.readU8(buf)
            if wf.apiVersion < 12.08 then
                data.yaw_collective_dynamic_gain.value = wf.mspHelper.readU8(buf)
                data.yaw_collective_dynamic_decay.value = wf.mspHelper.readU8(buf)
            else
                buf.offset = buf.offset + 2
            end
            data.pitch_collective_ff_gain.value = wf.mspHelper.readU8(buf)
            data.angle_level_strength.value = wf.mspHelper.readU8(buf)
            data.angle_level_limit.value = wf.mspHelper.readU8(buf)
            data.horizon_level_strength.value = wf.mspHelper.readU8(buf)
            data.trainer_gain.value = wf.mspHelper.readU8(buf)
            data.trainer_angle_limit.value = wf.mspHelper.readU8(buf)
            data.cyclic_cross_coupling_gain.value =  wf.mspHelper.readU8(buf)
            data.cyclic_cross_coupling_ratio.value =  wf.mspHelper.readU8(buf)
            data.cyclic_cross_coupling_cutoff.value =  wf.mspHelper.readU8(buf)
            data.offset_limit_roll.value = wf.mspHelper.readU8(buf)
            data.offset_limit_pitch.value = wf.mspHelper.readU8(buf)
            data.bterm_cutoff_roll.value = wf.mspHelper.readU8(buf)
            data.bterm_cutoff_pitch.value = wf.mspHelper.readU8(buf)
            data.bterm_cutoff_yaw.value = wf.mspHelper.readU8(buf)
            if wf.apiVersion >= 12.08 then
                data.yaw_inertia_precomp_gain.value = wf.mspHelper.readU8(buf)
                data.yaw_inertia_precomp_cutoff.value = wf.mspHelper.readU8(buf)
            end
            callback(callbackParam, data)
        end,
        simulatorResponse = { 3, 25, 250, 0, 12, 0, 1, 30, 30, 45, 50, 50, 100, 15, 15, 20, 2, 10, 10, 15, 100, 100, 5, 0, 30, 0, 25, 0, 40, 55, 40, 75, 20, 25, 0, 15, 45, 45, 15, 15, 20, 0, 0 },
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
    wf.mspHelper.writeU8(message.payload, data.error_decay_time_ground.value)
    wf.mspHelper.writeU8(message.payload, data.error_decay_time_cyclic.value)
    wf.mspHelper.writeU8(message.payload, data.error_decay_time_yaw.value)
    wf.mspHelper.writeU8(message.payload, data.error_decay_limit_cyclic.value)
    wf.mspHelper.writeU8(message.payload, data.error_decay_limit_yaw.value)
    if wf.apiVersion < 12.09 then
        wf.mspHelper.writeU8(message.payload, data.error_rotation.value)
    else
        wf.mspHelper.writeU8(message.payload, 0)
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
    wf.mspHelper.writeU8(message.payload, data.yaw_cw_stop_gain.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_ccw_stop_gain.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_precomp_cutoff.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_cyclic_ff_gain.value)
    wf.mspHelper.writeU8(message.payload, data.yaw_collective_ff_gain.value)
    if wf.apiVersion < 12.08 then
        wf.mspHelper.writeU8(message.payload, data.yaw_collective_dynamic_gain.value)
        wf.mspHelper.writeU8(message.payload, data.yaw_collective_dynamic_decay.value)
    else
        wf.mspHelper.writeU8(message.payload, 0)
        wf.mspHelper.writeU8(message.payload, 0)
    end
    wf.mspHelper.writeU8(message.payload, data.pitch_collective_ff_gain.value)
    wf.mspHelper.writeU8(message.payload, data.angle_level_strength.value)
    wf.mspHelper.writeU8(message.payload, data.angle_level_limit.value)
    wf.mspHelper.writeU8(message.payload, data.horizon_level_strength.value)
    wf.mspHelper.writeU8(message.payload, data.trainer_gain.value)
    wf.mspHelper.writeU8(message.payload, data.trainer_angle_limit.value)
    wf.mspHelper.writeU8(message.payload, data.cyclic_cross_coupling_gain.value)
    wf.mspHelper.writeU8(message.payload, data.cyclic_cross_coupling_ratio.value)
    wf.mspHelper.writeU8(message.payload, data.cyclic_cross_coupling_cutoff.value)
    wf.mspHelper.writeU8(message.payload, data.offset_limit_roll.value)
    wf.mspHelper.writeU8(message.payload, data.offset_limit_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.bterm_cutoff_roll.value)
    wf.mspHelper.writeU8(message.payload, data.bterm_cutoff_pitch.value)
    wf.mspHelper.writeU8(message.payload, data.bterm_cutoff_yaw.value)
    if wf.apiVersion >= 12.08 then
        wf.mspHelper.writeU8(message.payload, data.yaw_inertia_precomp_gain.value)
        wf.mspHelper.writeU8(message.payload, data.yaw_inertia_precomp_cutoff.value)
    end
    wf.mspQueue:add(message)
end

return {
    read = getPidProfile,
    write = setPidProfile,
    getDefaults = getDefaults
}