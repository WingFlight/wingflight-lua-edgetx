-- WingFlight's mixer is a generic rule-based system (MSP_MIXER_INPUTS/MSP_MIXER_RULES/
-- MSP_MIXER_CURVES below), not Rotorflight's helicopter swashplate mixer. MSP_MIXER_CONFIG
-- itself now carries only a descriptive `model_type` -- the firmware does not branch on it,
-- it just lets the UI show a simplified named-airframe view vs. the raw rule editor.

local MIXER_INPUT_COUNT = 27 -- MIXER_IN_COUNT (mixer.h): NONE + 26 named stabilized/RC-command/RC-channel inputs
local MIXER_RULE_COUNT = 32
local MIXER_CURVE_COUNT = 8
local MIXER_CURVE_POINTS = 9

local function getDefaults()
    local defaults = {}
    defaults.model_type = { min = 0, max = 5, table = {
        [0] = "Regular Airplane", "Flying Wing", "V-Tail Airplane", "Delta Wing", "Rudder/Elevator Trainer", "Custom"
    } }
    return defaults
end

local function getMixerConfig(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 42, -- MSP_MIXER_CONFIG
        processReply = function(self, buf)
            data.model_type.value = wf.mspHelper.readU8(buf)
            callback(callbackParam, data)
        end,
        simulatorResponse = { 0 },
    }
    wf.mspQueue:add(message)
end

local function setMixerConfig(data)
    local message = {
        command = 43, -- MSP_SET_MIXER_CONFIG
        payload = {}
    }
    wf.mspHelper.writeU8(message.payload, data.model_type.value)
    wf.mspQueue:add(message)
end

-- Per-input stabilized-axis gain/limits, one entry per MIXER_IN_* enum value in the
-- firmware (stabilized roll/pitch/yaw/throttle, RC command roll/pitch/yaw/throttle,
-- RC channel roll/pitch/yaw/throttle/aux1-3/8-18). Always a fixed MIXER_INPUT_COUNT-size
-- array on the wire; there's no per-input "hidden" flag, all 26 slots are always sent.

local function getMixerInputs(callback, callbackParam)
    local message = {
        command = 170, -- MSP_MIXER_INPUTS
        processReply = function(self, buf)
            local inputs = {}
            for i = 0, MIXER_INPUT_COUNT - 1 do
                inputs[i] = {
                    rate = { value = wf.mspHelper.readS16(buf), min = -2500, max = 2500 },
                    min = { value = wf.mspHelper.readS16(buf), min = -2500, max = 2500 },
                    max = { value = wf.mspHelper.readS16(buf), min = -2500, max = 2500 },
                }
            end
            callback(callbackParam, inputs)
        end,
    }
    wf.mspQueue:add(message)
end

local function setMixerInput(index, input)
    local message = {
        command = 171, -- MSP_SET_MIXER_INPUT
        payload = { index }
    }
    wf.mspHelper.writeU16(message.payload, input.rate.value)
    wf.mspHelper.writeU16(message.payload, input.min.value)
    wf.mspHelper.writeU16(message.payload, input.max.value)
    wf.mspQueue:add(message)
end

-- The 32-slot mixer rule table. There is no bulk "set all" or single "get one rule"
-- command on the firmware -- rules are always fetched in bulk and written back one at a
-- time by index.

local function getMixerRules(callback, callbackParam)
    local message = {
        command = 172, -- MSP_MIXER_RULES
        processReply = function(self, buf)
            local rules = {}
            for i = 0, MIXER_RULE_COUNT - 1 do
                rules[i] = {
                    oper = { value = wf.mspHelper.readU8(buf), min = 0, max = 3, table = { [0] = "None", "Set", "Add", "Mul" } },
                    input = { value = wf.mspHelper.readU8(buf), min = 0, max = MIXER_INPUT_COUNT - 1 },
                    output = { value = wf.mspHelper.readU8(buf), min = 0, max = 30 },
                    offset = { value = wf.mspHelper.readS16(buf), min = -2500, max = 2500 },
                    weight = { value = wf.mspHelper.readS16(buf), min = -10000, max = 10000 },
                    weightNeg = { value = wf.mspHelper.readS16(buf), min = -10000, max = 10000 },
                    speed = { value = wf.mspHelper.readU16(buf), min = 0, max = 60000 },
                    curve = { value = wf.mspHelper.readU8(buf), min = 0, max = MIXER_CURVE_COUNT },
                    condition = { value = wf.mspHelper.readU8(buf), min = 0, max = 16 },
                }
            end
            callback(callbackParam, rules)
        end,
    }
    wf.mspQueue:add(message)
end

local function setMixerRule(index, rule)
    local message = {
        command = 173, -- MSP_SET_MIXER_RULE
        payload = { index }
    }
    wf.mspHelper.writeU8(message.payload, rule.oper.value)
    wf.mspHelper.writeU8(message.payload, rule.input.value)
    wf.mspHelper.writeU8(message.payload, rule.output.value)
    wf.mspHelper.writeU16(message.payload, rule.offset.value)
    wf.mspHelper.writeU16(message.payload, rule.weight.value)
    wf.mspHelper.writeU16(message.payload, rule.weightNeg.value)
    wf.mspHelper.writeU16(message.payload, rule.speed.value)
    wf.mspHelper.writeU8(message.payload, rule.curve.value)
    wf.mspHelper.writeU8(message.payload, rule.condition.value)
    wf.mspQueue:add(message)
end

-- 8 curve slots a mixer rule's `curve` field can reference, each up to MIXER_CURVE_POINTS
-- (x,y) points. Firmware always sends/expects all MIXER_CURVE_POINTS slots regardless of
-- `count` (the extra points are simply unused), and rejects count outside [2, MIXER_CURVE_POINTS].

local function getMixerCurves(callback, callbackParam)
    local message = {
        command = 177, -- MSP_MIXER_CURVES
        processReply = function(self, buf)
            local curves = {}
            for i = 0, MIXER_CURVE_COUNT - 1 do
                local curve = { count = wf.mspHelper.readU8(buf), points = {} }
                for p = 0, MIXER_CURVE_POINTS - 1 do
                    curve.points[p] = {
                        x = wf.mspHelper.readS16(buf),
                        y = wf.mspHelper.readS16(buf),
                    }
                end
                curves[i] = curve
            end
            callback(callbackParam, curves)
        end,
    }
    wf.mspQueue:add(message)
end

local function setMixerCurve(index, curve)
    local message = {
        command = 178, -- MSP_SET_MIXER_CURVE
        payload = { index }
    }
    wf.mspHelper.writeU8(message.payload, curve.count)
    for p = 0, MIXER_CURVE_POINTS - 1 do
        local point = curve.points[p] or { x = 0, y = 0 }
        wf.mspHelper.writeU16(message.payload, point.x)
        wf.mspHelper.writeU16(message.payload, point.y)
    end
    wf.mspQueue:add(message)
end

-- Per mixer-INPUT override (not per-servo). Sentinel values below match firmware's
-- MIXER_OVERRIDE_OFF/MIXER_OVERRIDE_PASSTHROUGH exactly; valid index range is
-- 0..MIXER_INPUT_COUNT-1 (26 stabilized-axis/RC inputs), not a fixed heli servo count.

local function disableMixerOverride(mixerIndex)
    local message = {
        command = 191, -- MSP_SET_MIXER_OVERRIDE
        payload = { mixerIndex }
    }
    wf.mspHelper.writeU16(message.payload, 2501) -- MIXER_OVERRIDE_OFF
    wf.mspQueue:add(message)
end

local function enableMixerOverride(mixerIndex)
    local message = {
        command = 191, -- MSP_SET_MIXER_OVERRIDE
        payload = { mixerIndex }
    }
    wf.mspHelper.writeU16(message.payload, 2502) -- MIXER_OVERRIDE_PASSTHROUGH
    wf.mspQueue:add(message)
end

return {
    read = getMixerConfig,
    write = setMixerConfig,
    getDefaults = getDefaults,
    getMixerInputs = getMixerInputs,
    setMixerInput = setMixerInput,
    getMixerRules = getMixerRules,
    setMixerRule = setMixerRule,
    getMixerCurves = getMixerCurves,
    setMixerCurve = setMixerCurve,
    disableOverride = disableMixerOverride,
    enableOverride = enableMixerOverride,
    MIXER_INPUT_COUNT = MIXER_INPUT_COUNT,
    MIXER_RULE_COUNT = MIXER_RULE_COUNT,
    MIXER_CURVE_COUNT = MIXER_CURVE_COUNT,
    MIXER_CURVE_POINTS = MIXER_CURVE_POINTS,
}
