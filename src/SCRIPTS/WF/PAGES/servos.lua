local template = wf.executeScript(wf.radio.template)
local mspServos = wf.useApi("mspServos")
local mspMixer = wf.useApi("mspMixer")
local margin = template.margin
local indent = template.indent
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local sp = template.listSpacing.field
local yMinLim = wf.radio.yMinLimit
local x = margin
local y = yMinLim - lineSpacing
local function incY(val) y = y + val return y end
local labels = {}
local fields = {}
local servoConfigs = {}
local selectedServoIndex = 0
local updateSelectedServoConfiguration = false
local overrideAllServos = false
local mixerConfig = mspMixer.getDefaults()
local pwmRates = {}
local storedPwmRate

local  function setValues(servoIndex)
    local config = servoConfigs[servoIndex]
    if not config then return end
    fields[1].data.value = servoIndex
    fields[2].data = config.mid
    fields[3].data = config.min
    fields[4].data = config.max
    fields[5].data = config.scaleNeg
    fields[6].data = config.scalePos
    fields[7].data = config.speed
end

-- Field event functions

local function onChangeServo(field, page)
    selectedServoIndex = field.data.value
    wf.lastChangedServo = selectedServoIndex
    setValues(selectedServoIndex)
    wf.onPageReady(page)
end

local function onPreEditCenter(field, page)
    if not overrideAllServos then
        mspServos.enableServoOverride(selectedServoIndex)
    end
end

local function onChangeCenter(field, page)
    updateSelectedServoConfiguration = true
end

local function onPostEditCenter(field, page)
    if not overrideAllServos then
        mspServos.disableServoOverride(selectedServoIndex)
    end
end

local function onClickOverride(field, page)
    --wf.lcdNeedsInvalidate = true
    if not overrideAllServos then
        overrideAllServos = true
        field.t = "[Disable Override]"
    else
        overrideAllServos = false
        field.t = "[Override All Servos]"
    end

    for i = 0, #servoConfigs do
        if overrideAllServos then
            mspServos.enableServoOverride(i)
        else
            mspServos.disableServoOverride(i)
        end
    end
end

-- Index N is servo N+1, on a PWM output, a bus channel or both -- which function each one
-- performs is assigned via the mixer rules, not a fixed per-index meaning, so this just
-- labels the servos numerically (1-based for display).
local servoIndexLabels = { [0] = "1" }
for i = 1, 23 do servoIndexLabels[i] = tostring(i + 1) end
fields[1] = { t = "Servo",      x = x,          y = incY(lineSpacing), sp = x + sp, data = { min = 0, max = 23, table = servoIndexLabels }, postEdit = onChangeServo }
fields[2] = { t = "Center",     x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoMid", preEdit = onPreEditCenter, change = onChangeCenter, postEdit = onPostEditCenter }
fields[3] = { t = "Min",        x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoMin" }
fields[4] = { t = "Max",        x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoMax" }
fields[5] = { t = "Scale neg",  x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoScaleNeg" }
fields[6] = { t = "Scale pos",  x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoScalePos" }
fields[7] = { t = "Speed",      x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoSpeed" }
incY(lineSpacing * 0.5)
fields[8] = { t = "[Override All Servos]", x = x + indent * 2, y = incY(lineSpacing), preEdit = onClickOverride }

-- One update rate for every PWM servo output (servo_pwm_rate), used from the next boot.
-- High speed is for digital servos only. The value has a line of its own: the choices
-- don't fit next to a label on the small screens.
incY(lineSpacing * 0.5)
labels[#labels + 1] = { t = "PWM Update Rate", x = x, y = incY(lineSpacing) }
fields[9] = { x = x + indent, y = incY(lineSpacing), w = 170 }
labels[#labels + 1] = { t = "High speed: digital only", x = x, y = incY(lineSpacing), bold = false }

local function receivedMixerConfig(page, config)
    local rate = config.servo_pwm_rate
    if not rate then return end
    storedPwmRate = rate
    pwmRates = { [0] = 50, 333 }
    local names = { [0] = "Standard (50 Hz)", "High speed (333 Hz)" }
    local selected = 0
    if rate == 333 then
        selected = 1
    elseif rate ~= 50 then
        -- the stored rate is neither: offer it as it is
        selected = 2
        pwmRates[2] = rate
        names[2] = rate .. " Hz"
    end
    page.fields[9].data = { value = selected, min = 0, max = #names, table = names }
end

local function receivedServoConfigurations(page, configs)
    servoConfigs = configs
    selectedServoIndex = wf.lastChangedServo or 0
    if selectedServoIndex > #configs then selectedServoIndex = 0 end
    setValues(selectedServoIndex)
    page.fields[1].data.max = #configs
    wf.onPageReady(page)
end

return {
    read = function(self)
        mspMixer.read(receivedMixerConfig, self, mixerConfig)
        mspServos.getServoConfigurations(receivedServoConfigurations, self)
    end,
    write = function(self)
        local pwmRate = storedPwmRate and pwmRates[fields[9].data.value]
        local pwmRateChanged = pwmRate and pwmRate ~= storedPwmRate
        if not servoConfigs[0] and not pwmRateChanged then return end
        if pwmRateChanged then
            mixerConfig.servo_pwm_rate = pwmRate
            mspMixer.write(mixerConfig)
        end
        if servoConfigs[0] then
            for servoIndex = 0, #servoConfigs do
                mspServos.setServoConfiguration(servoIndex, servoConfigs[servoIndex])
            end
        end
        -- the PWM rate is applied at boot
        wf.settingsSaved(true, pwmRateChanged or false)
    end,
    timer = function(self)
        if updateSelectedServoConfiguration then
            mspServos.setServoConfiguration(selectedServoIndex, servoConfigs[selectedServoIndex])
            updateSelectedServoConfiguration = false
        end
    end,
    title       = "Servos",
    labels      = labels,
    fields      = fields
}
