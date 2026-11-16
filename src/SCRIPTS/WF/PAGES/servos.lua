local template = wf.executeScript(wf.radio.template)
local mspServos = wf.useApi("mspServos")
-- Dropped when the firmware doesn't have servo roles.
local mspServoRoles = wf.useApi("mspServoRoles")
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
-- Role byte of each servo (0-based) as edited, and as last read or written.
local roleValues = {}
local savedRoleValues = {}
local rolesReading = false
local roleField
local roleBeforeChange = 0

local  function setValues(servoIndex)
    local config = servoConfigs[servoIndex]
    if not config then return end
    fields[1].data.value = servoIndex
    -- The Role field is fields[2] once the roles are read.
    local f = 2
    if fields[2] == roleField then
        local role = mspServoRoles.roleOf(roleValues[servoIndex])
        -- 29 and 30 are reserved: only the selected servo's own one is listed.
        local names = roleField.data.table
        names[29], names[30] = nil, nil
        if not names[role] then names[role] = "Unknown" end
        roleField.data.value = role
        f = 3
    end
    fields[f].data = config.mid
    fields[f + 1].data = config.min
    fields[f + 2].data = config.max
    fields[f + 3].data = config.scaleNeg
    fields[f + 4].data = config.scalePos
    fields[f + 5].data = config.speed
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

-- The servo number with its role where there is room: "3 Elevator".
local function setServoLabels()
    if LCD_W < 212 then return end
    for i = 0, #roleValues do
        local label = mspServoRoles.getLabel(roleValues, i)
        servoIndexLabels[i] = tostring(i + 1) .. (label ~= "" and " " .. label or "")
    end
end

local function onPreEditRole(field, page)
    roleBeforeChange = field.data.value
end

-- Step over the reserved roles with the wheel (the choice list on LVGL radios
-- doesn't hold them).
local function onChangeRole(field, page)
    local data = field.data
    local step = data.value < roleBeforeChange and -1 or 1
    while not data.table[data.value] do
        data.value = data.value + step
    end
    roleBeforeChange = data.value
end

-- Servos with the same role are numbered again; they are sent on Save.
local function onPostEditRole(field, page)
    if field.data.value ~= mspServoRoles.roleOf(roleValues[selectedServoIndex]) then
        mspServoRoles.setRole(roleValues, selectedServoIndex, field.data.value)
        setServoLabels()
        wf.onPageReady(page)
    end
end

fields[1] = { t = "Servo",      x = x,          y = incY(lineSpacing), sp = x + sp, data = { min = 0, max = 23, table = servoIndexLabels }, postEdit = onChangeServo }
fields[2] = { t = "Center",     x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoMid", preEdit = onPreEditCenter, change = onChangeCenter, postEdit = onPostEditCenter }
fields[3] = { t = "Min",        x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoMin" }
fields[4] = { t = "Max",        x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoMax" }
fields[5] = { t = "Scale neg",  x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoScaleNeg" }
fields[6] = { t = "Scale pos",  x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoScalePos" }
fields[7] = { t = "Speed",      x = x + indent, y = incY(lineSpacing), sp = x + sp, id = "servoSpeed" }
incY(lineSpacing * 0.5)
fields[8] = { t = "[Override All Servos]", x = x + indent * 2, y = incY(lineSpacing), preEdit = onClickOverride }
-- Added below the servo once the roles are read; firmware without them shows the page as before.
roleField = { t = "Role", x = x + indent, y = fields[2].y, sp = x + sp, data = { value = 0, min = 0, max = 31, table = mspServoRoles.roleNames }, preEdit = onPreEditRole, change = onChangeRole, postEdit = onPostEditRole }

-- The PWM update rate (servo_pwm_rate) is not offered here: 50 Hz suits nearly every
-- model, and the Configurator's Servos tab sets it for the rest.

local function receivedServoRoles(page, values)
    rolesReading = false
    roleValues = values
    savedRoleValues = {}
    for i = 0, #values do savedRoleValues[i] = values[i] end
    if fields[2] ~= roleField then
        for i = 2, #fields do fields[i].y = fields[i].y + lineSpacing end
        table.insert(fields, 2, roleField)
        fields[1].w = 150
    end
    setServoLabels()
    setValues(selectedServoIndex)
    wf.onPageReady(page)
end

local function servoRolesUnsupported(page)
    rolesReading = false
    mspServoRoles = nil
    wf.onPageReady(page)
end

local function receivedServoConfigurations(page, configs)
    servoConfigs = configs
    selectedServoIndex = wf.lastChangedServo or 0
    if selectedServoIndex > #configs then selectedServoIndex = 0 end
    setValues(selectedServoIndex)
    page.fields[1].data.max = #configs
    if not mspServoRoles then
        wf.onPageReady(page)
    elseif not rolesReading then
        rolesReading = true
        mspServoRoles.read(receivedServoRoles, page, servoRolesUnsupported)
    end
end

return {
    read = function(self)
        mspServos.getServoConfigurations(receivedServoConfigurations, self)
    end,
    write = function(self)
        if servoConfigs[0] then
            for servoIndex = 0, #servoConfigs do
                mspServos.setServoConfiguration(servoIndex, servoConfigs[servoIndex])
            end
            if mspServoRoles then
                for servoIndex = 0, #roleValues do
                    if roleValues[servoIndex] ~= savedRoleValues[servoIndex] then
                        mspServoRoles.write(servoIndex, roleValues[servoIndex])
                        savedRoleValues[servoIndex] = roleValues[servoIndex]
                    end
                end
            end
            wf.settingsSaved(true, false)
        end
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
