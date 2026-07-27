local function getDefaults()
    local defaults = {}
    defaults.main_rotor_dir = { min = 0, max = 1, table = { [0] = "CW", "CCW" } }
    defaults.tail_rotor_mode = { min = 0, max = 2, table = { [0] = "VARIABLE", "MOTORIZED", "BIDIRECTIONAL" } }
    defaults.tail_motor_idle = { min = 0, max = 250, scale = 10, unit = wf.units.percentage }
    defaults.tail_center_trim = { min = -500, max = 500, scale = 10, unit = wf.units.percentage }
    defaults.swash_type = { min = 0, max = 6, table = { [0] = "NONE", "PASSTHROUGH", "CP120", "CP135", "CP140", "FP90L", "FP90V" } }
    defaults.swash_ring = { min = 0, max = 100 }
    defaults.swash_phase = { min = -1800, max = 1800, scale = 10, mult = 5, unit = wf.units.degrees }
    defaults.swash_pitch_limit = { min = 0, max = 3000, scale = 1000/12, mult = 100/12, unit = wf.units.degrees }
    defaults.swash_trim_roll = { min = -1000, max = 1000, scale = 10, unit = wf.units.percentage }
    defaults.swash_trim_pitch = { min = -1000, max = 1000, scale = 10, unit = wf.units.percentage }
    defaults.swash_trim_collective = { min = -1000, max = 1000, scale = 10, unit = wf.units.percentage }
    defaults.swash_tta_precomp = { min = 0, max = 250, scale = 10 }
    defaults.swash_geo_correction = { min = -125, max = 125, scale = 5, unit = wf.units.percentage }
    if wf.apiVersion >= 12.08 then
        defaults.collective_tilt_correction_pos = { min = -100, max = 100, unit = wf.units.percentage }
        defaults.collective_tilt_correction_neg = { min = -100, max = 100, unit = wf.units.percentage }
    end
 return defaults
end

local function getMixerConfig(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 42, -- MSP_MIXER_CONFIG
        processReply = function(self, buf)
            data.main_rotor_dir.value = wf.mspHelper.readU8(buf)
            data.tail_rotor_mode.value = wf.mspHelper.readU8(buf)
            data.tail_motor_idle.value = wf.mspHelper.readU8(buf)
            data.tail_center_trim.value = wf.mspHelper.readS16(buf)
            data.swash_type.value = wf.mspHelper.readU8(buf)
            data.swash_ring.value = wf.mspHelper.readU8(buf)
            data.swash_phase.value = wf.mspHelper.readS16(buf)
            data.swash_pitch_limit.value = wf.mspHelper.readU16(buf)
            data.swash_trim_roll.value = wf.mspHelper.readS16(buf);
            data.swash_trim_pitch.value = wf.mspHelper.readS16(buf);
            data.swash_trim_collective.value = wf.mspHelper.readS16(buf);
            data.swash_tta_precomp.value = wf.mspHelper.readU8(buf)
            data.swash_geo_correction.value = wf.mspHelper.readS8(buf)
            if wf.apiVersion >= 12.08 then
                data.collective_tilt_correction_pos.value = wf.mspHelper.readS8(buf)
                data.collective_tilt_correction_neg.value = wf.mspHelper.readS8(buf)
            end
            callback(callbackParam, data)
        end,
        simulatorResponse = { 0, 0, 0, 0, 0, 2, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    }
    wf.mspQueue:add(message)
end

local function setMixerConfig(data)
    local message = {
        command = 43, -- MSP_SET_MIXER_CONFIG
        payload = {},
        simulatorResponse = {}
    }
    wf.mspHelper.writeU8(message.payload, data.main_rotor_dir.value)
    wf.mspHelper.writeU8(message.payload, data.tail_rotor_mode.value)
    wf.mspHelper.writeU8(message.payload, data.tail_motor_idle.value)
    wf.mspHelper.writeU16(message.payload, data.tail_center_trim.value)
    wf.mspHelper.writeU8(message.payload, data.swash_type.value)
    wf.mspHelper.writeU8(message.payload, data.swash_ring.value)
    wf.mspHelper.writeU16(message.payload, data.swash_phase.value)
    wf.mspHelper.writeU16(message.payload, data.swash_pitch_limit.value)
    wf.mspHelper.writeU16(message.payload, data.swash_trim_roll.value);
    wf.mspHelper.writeU16(message.payload, data.swash_trim_pitch.value);
    wf.mspHelper.writeU16(message.payload, data.swash_trim_collective.value);
    wf.mspHelper.writeU8(message.payload, data.swash_tta_precomp.value)
    wf.mspHelper.writeU8(message.payload, data.swash_geo_correction.value)
    if wf.apiVersion >= 12.08 then
        wf.mspHelper.writeU8(message.payload, data.collective_tilt_correction_pos.value)
        wf.mspHelper.writeU8(message.payload, data.collective_tilt_correction_neg.value)
    end
    wf.mspQueue:add(message)
end

local function disableMixerOverride(mixerIndex)
    local message = {
        command = 191, -- MSP_SET_MIXER_OVERRIDE
        payload = { mixerIndex }
    }
    wf.mspHelper.writeU16(message.payload, 2501)
    wf.mspQueue:add(message)
end

local function enableMixerOverride(mixerIndex)
    local message = {
        command = 191, -- MSP_SET_MIXER_OVERRIDE
        payload = { mixerIndex }
    }
    wf.mspHelper.writeU16(message.payload, 2502)
    wf.mspQueue:add(message)
end


return {
    read = getMixerConfig,
    write = setMixerConfig,
    getDefaults = getDefaults,
    disableOverride = disableMixerOverride,
    enableOverride = enableMixerOverride
}