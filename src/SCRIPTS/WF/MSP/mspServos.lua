-- MSP_SERVO_CONFIGURATIONS lists the configured PWM servos, then all 24 bus servos
-- when bus servos are configured. MSP_SET_SERVO_OVERRIDE takes the firmware's own
-- servo index instead, where bus servos start at 8 (BUS_SERVO_OFFSET).
local BUS_SERVO_OFFSET = 8
local BUS_SERVO_CHANNELS = 24
local listedServoCount = 0

local function overrideIndex(servoIndex)
    local pwmCount = listedServoCount - BUS_SERVO_CHANNELS
    if pwmCount >= 0 and servoIndex >= pwmCount then
        return BUS_SERVO_OFFSET + servoIndex - pwmCount
    end
    return servoIndex
end

local function getServoConfigurations(callback, callbackParam)
    local message = {
        command = 120, -- MSP_SERVO_CONFIGURATIONS
        processReply = function(self, buf)
            local servoCount = wf.mspHelper.readU8(buf)
            listedServoCount = servoCount
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
            callback(callbackParam, configs)
        end,
        simulatorResponse = {
            2,
            220, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0,
            221, 5, 68, 253, 188, 2, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
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
    wf.mspQueue:add(message)
end

local function disableServoOverride(servoIndex)
    local message = {
        command = 193, -- MSP_SET_SERVO_OVERRIDE
        payload = { overrideIndex(servoIndex) }
    }
    wf.mspHelper.writeU16(message.payload, 2001)
    wf.mspQueue:add(message)
end

local function enableServoOverride(servoIndex)
    local message = {
        command = 193, -- MSP_SET_SERVO_OVERRIDE
        payload = { overrideIndex(servoIndex) }
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