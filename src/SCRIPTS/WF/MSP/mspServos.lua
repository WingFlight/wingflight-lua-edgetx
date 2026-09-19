local function getServoConfigurations(callback, callbackParam)
    local message = {
        command = 120, -- MSP_SERVO_CONFIGURATIONS
        processReply = function(self, buf)
            local servoCount = wf.mspHelper.readU8(buf)
            --wf.print("Servo count "..tostring(servoCount))
            local configs = {}
            for i = 0, servoCount-1 do
                local config = {}
                config.mid = { value = wf.mspHelper.readU16(buf), min = 50,    max = 2250 }
                config.min = { value = wf.mspHelper.readS16(buf), min = -1000, max = 1000 }
                config.max = { value = wf.mspHelper.readS16(buf), min = -1000, max = 1000 }
                config.scaleNeg = { value = wf.mspHelper.readU16(buf), min = 100, max = 1000 }
                config.scalePos = { value = wf.mspHelper.readU16(buf), min = 100, max = 1000 }
                config.rate = { value = wf.mspHelper.readU16(buf), min = 50, max = 5000, unit = wf.units.herz }
                config.speed = { value = wf.mspHelper.readU16(buf), min = 0, max = 60000, unit = wf.units.milliseconds }
                config.flags = { value = wf.mspHelper.readU16(buf), min = 0, max = 3 }
                configs[i] = config
            end
            -- FC API 22.3+ appends one S16 trim per servo after the records; older FCs don't.
            -- The limit is 20% of the servo scale (larger of neg/pos), same as the firmware.
            if #buf - (buf.offset - 1) >= servoCount * 2 then
                for i = 0, servoCount-1 do
                    local config = configs[i]
                    local limit = math.floor(math.max(config.scaleNeg.value, config.scalePos.value) * 20 / 100)
                    config.trim = { value = wf.mspHelper.readS16(buf), min = -limit, max = limit }
                end
            end
            callback(callbackParam, configs)
        end,
        simulatorResponse = {
            2,
            220, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0,
            221, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0,
            0, 0, 0, 0
        }
    }
    wf.mspQueue:add(message)
end

local function setServoConfiguration(servoIndex, servoConfig)
    local message = {
        command = 212, -- MSP_SET_SERVO_CONFIGURATION
        payload = {}
    }
    wf.mspHelper.writeU8(message.payload, servoIndex)
    wf.mspHelper.writeU16(message.payload, servoConfig.mid.value)
    wf.mspHelper.writeU16(message.payload, servoConfig.min.value)
    wf.mspHelper.writeU16(message.payload, servoConfig.max.value)
    wf.mspHelper.writeU16(message.payload, servoConfig.scaleNeg.value)
    wf.mspHelper.writeU16(message.payload, servoConfig.scalePos.value)
    wf.mspHelper.writeU16(message.payload, servoConfig.rate.value)
    wf.mspHelper.writeU16(message.payload, servoConfig.speed.value)
    wf.mspHelper.writeU16(message.payload, servoConfig.flags.value)
    -- Only sent when the FC reported a trim (API 22.3+), otherwise the FC would reject the length.
    if servoConfig.trim then
        wf.mspHelper.writeU16(message.payload, servoConfig.trim.value)
    end
    wf.mspQueue:add(message)
end

local function disableServoOverride(servoIndex)
    local message = {
        command = 193, -- MSP_SET_SERVO_OVERRIDE
        payload = { servoIndex }
    }
    wf.mspHelper.writeU16(message.payload, 2001)
    wf.mspQueue:add(message)
end

local function enableServoOverride(servoIndex)
    local message = {
        command = 193, -- MSP_SET_SERVO_OVERRIDE
        payload = { servoIndex }
    }
    wf.mspHelper.writeU16(message.payload, 0)
    wf.mspQueue:add(message)
end

return {
    enableServoOverride = enableServoOverride,
    disableServoOverride = disableServoOverride,
    getServoConfigurations = getServoConfigurations,
    setServoConfiguration = setServoConfiguration
}