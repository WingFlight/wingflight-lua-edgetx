-- Servo index N is servo S(N+1) in every servo message (API 22.16), whether the servo
-- is sent on a PWM output, a bus channel (SBUS, F.Bus) or both.
-- MSP_SERVO_CONFIGURATIONS lists the servos in use; the set messages take any servo 0-23.

local function getServoConfigurations(callback, callbackParam)
    local message = {
        command = 120, -- MSP_SERVO_CONFIGURATIONS
        processReply = function(self, buf)
            local servoCount = wf.mspHelper.readU8(buf)
            --wf.print("Servo count "..tostring(servoCount))
            local configs = {}
            for i = 0, servoCount-1 do
                local config = {}
                config.mid = { value = wf.mspHelper.readU16(buf), min = 1000,  max = 2000 }
                config.min = { value = wf.mspHelper.readS16(buf), min = -1000, max = 0 }
                config.max = { value = wf.mspHelper.readS16(buf), min = 0,     max = 1000 }
                config.scaleNeg = { value = wf.mspHelper.readU16(buf), min = 50, max = 1000 }
                config.scalePos = { value = wf.mspHelper.readU16(buf), min = 50, max = 1000 }
                config.speed = { value = wf.mspHelper.readU16(buf), min = 0, max = 60000, unit = wf.units.milliseconds }
                config.flags = { value = wf.mspHelper.readU16(buf), min = 0, max = 3 }
                configs[i] = config
            end
            callback(callbackParam, configs)
        end,
        simulatorResponse = {
            2,
            220, 5, 168, 253, 88, 2, 244, 1, 244, 1, 0, 0, 0, 0,
            221, 5, 168, 253, 88, 2, 244, 1, 244, 1, 0, 0, 0, 0
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
    wf.mspHelper.writeU16(message.payload, servoConfig.speed.value)
    wf.mspHelper.writeU16(message.payload, servoConfig.flags.value)
    wf.mspQueue:add(message)
end

-- MSP2_WING_SERVO_NAMES (0x5F3A, firmware #286): a short name per servo, for
-- reference only. Reply: U8 servo count (24), U8 name length N (8), then N
-- zero-padded ASCII bytes per servo. callback(param, names) gets names[i] for
-- servo i (0-based), "" for one without a name, or nil on firmware without
-- names, which answers with an MSP error. Names are set in the Configurator,
-- the Ethos suite or the CLI; these scripts only show them.
local function getServoNames(callback, callbackParam)
    local message = {
        command = 0x5F3A, -- MSP2_WING_SERVO_NAMES
        processReply = function(self, buf)
            local count = wf.mspHelper.readU8(buf) or 0
            local length = wf.mspHelper.readU8(buf) or 0
            local names = {}
            for servo = 0, count - 1 do
                local name = ""
                for _ = 1, length do
                    local c = wf.mspHelper.readU8(buf) or 0
                    if c ~= 0 then name = name .. string.char(c) end
                end
                names[servo] = name
            end
            callback(callbackParam, names)
        end,
        errorHandler = function(self)
            callback(callbackParam, nil)
        end,
        -- 24 servos, 8 bytes each; the first two named like the default mix
        simulatorResponse = {
            24, 8,
            76, 32, 65, 73, 76, 0, 0, 0, -- L AIL
            82, 32, 65, 73, 76, 0, 0, 0, -- R AIL
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        }
    }
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
    getServoNames = getServoNames,
    setServoConfiguration = setServoConfiguration
}
