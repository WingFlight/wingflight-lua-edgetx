local template = wf.executeScript(wf.radio.template)
local settings = wf.loadSettings()
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
local hideShow = { [0] = "Hide", "Show" }
local offOn = { [0] = "Off", "On" }
local canUseLvgl = wf.executeScript("F/canUseLvgl")()

y = yMinLim - tableSpacing.header
labels[1] = { t = "Display FC Pages",        x = x, y = incY(lineSpacing) }
fields[1] = { t = "Status",                  x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[2] = { t = "Rates",                   x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[3] = { t = "Rate Dynamics",           x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[4] = { t = "PID Gains",               x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[5] = { t = "PID Controller",          x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[6] = { t = "Profile - Various",       x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[7] = { t = "Battery",                 x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[8] = { t = "Servos",                  x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[9] = { t = "Mixer",                   x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[10] = { t = "Gyro Filters",           x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[11] = { t = "Accelerometer Trim",     x = x + indent, y = incY(lineSpacing), sp = x + sp }

incY(lineSpacing * 0.5)
labels[2] = { t = "Display Various Pages",   x = x, y = incY(lineSpacing) }
fields[12] = { t = "Model",                  x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[13] = { t = "Experimental (!)",       x = x + indent, y = incY(lineSpacing), sp = x + sp }

incY(lineSpacing * 0.5)
labels[3] = { t = "Display ESC Pages",       x = x, y = incY(lineSpacing) }
fields[14] = { t = "AM32",                   x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[15] = { t = "BLHeli_S",               x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[16] = { t = "Bluejay",                x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[17] = { t = "FLYROTOR",               x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[18] = { t = "HW Platinum V5",         x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[19] = { t = "Scorpion Tribunus",      x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[20] = { t = "XDFly/OMP/ZTW",          x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[21] = { t = "YGE",                    x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[22] = { t = "ESC Sensor",             x = x + indent, y = incY(lineSpacing), sp = x + sp }

incY(lineSpacing * 0.5)
labels[4] = { t = "Wfbg Options",           x = x, y = incY(lineSpacing) }
fields[23] = { t = "Adjustment Teller",      x = x + indent, y = incY(lineSpacing), sp = x + sp }

if canUseLvgl then
    incY(lineSpacing * 0.5)
    labels[5] = { t = "Tool Options",        x = x, y = incY(lineSpacing) }
    fields[24] = { t = "Use touch UI",       x = x + indent, y = incY(lineSpacing), sp = x + sp }
end

local function setValues()
    fields[1].data = { value = settings.showStatus or 1, min = 0, max = 1, table = hideShow }
    fields[2].data = { value = settings.showRates or 1, min = 0, max = 1, table = hideShow }
    fields[3].data = { value = settings.showRateDynamics  or 1, min = 0, max = 1, table = hideShow }
    fields[4].data = { value = settings.showPidGains or 1, min = 0, max = 1, table = hideShow }
    fields[5].data = { value = settings.showPidController or 1, min = 0, max = 1, table = hideShow }
    fields[6].data = { value = settings.showProfileVarious or 1, min = 0, max = 1, table = hideShow }
    fields[7].data = { value = settings.showBattery or 1, min = 0, max = 1, table = hideShow }
    fields[8].data = { value = settings.showServos or 1, min = 0, max = 1, table = hideShow }
    fields[9].data = { value = settings.showMixer or 1, min = 0, max = 1, table = hideShow }
    fields[10].data = { value = settings.showGyroFilters or 1, min = 0, max = 1, table = hideShow }
    fields[11].data = { value = settings.showAccelerometerTrim or 1, min = 0, max = 1, table = hideShow }
    fields[12].data = { value = settings.showModelOnTx or 0, min = 0, max = 1, table = hideShow }
    fields[13].data = { value = settings.showExperimental or 0, min = 0, max = 1, table = hideShow }
    fields[14].data = { value = settings.showAm32 or 0, min = 0, max = 1, table = hideShow }
    fields[15].data = { value = settings.showBlheliS or 0, min = 0, max = 1, table = hideShow }
    fields[16].data = { value = settings.showBluejay or 0, min = 0, max = 1, table = hideShow }
    fields[17].data = { value = settings.showFlyRotor or 0, min = 0, max = 1, table = hideShow }
    fields[18].data = { value = settings.showPlatinumV5 or 0, min = 0, max = 1, table = hideShow }
    fields[19].data = { value = settings.showTribunus or 0, min = 0, max = 1, table = hideShow }
    fields[20].data = { value = settings.showXdfly or 0, min = 0, max = 1, table = hideShow }
    fields[21].data = { value = settings.showYge or 0, min = 0, max = 1, table = hideShow }
    fields[22].data = { value = settings.showEscSensor or 1, min = 0, max = 1, table = hideShow }
    fields[23].data = { value = settings.useAdjustmentTeller or 0, min = 0, max = 1, table = offOn }
    if canUseLvgl then
        fields[24].data = { value = settings.useLvgl or 1, min = 0, max = 1, table = offOn }
    end
end

return {
    read = function(self)
        setValues()
        wf.onPageReady(self)
    end,
    write = function(self)
        settings.showStatus = fields[1].data.value
        settings.showRates = fields[2].data.value
        settings.showRateDynamics = fields[3].data.value
        settings.showPidGains = fields[4].data.value
        settings.showPidController = fields[5].data.value
        settings.showProfileVarious = fields[6].data.value
        settings.showBattery = fields[7].data.value
        settings.showServos = fields[8].data.value
        settings.showMixer = fields[9].data.value
        settings.showGyroFilters = fields[10].data.value
        settings.showAccelerometerTrim = fields[11].data.value
        settings.showModelOnTx = fields[12].data.value
        settings.showExperimental = fields[13].data.value
        settings.showAm32 = fields[14].data.value
        settings.showBlheliS = fields[15].data.value
        settings.showBluejay = fields[16].data.value
        settings.showFlyRotor = fields[17].data.value
        settings.showPlatinumV5 = fields[18].data.value
        settings.showTribunus = fields[19].data.value
        settings.showXdfly = fields[20].data.value
        settings.showYge = fields[21].data.value
        settings.showEscSensor = fields[22].data.value
        if settings.useAdjustmentTeller ~= fields[23].data.value then
            settings.useAdjustmentTeller = fields[23].data.value
            wf.executeScript("F/pilotConfigReset")() -- restart wfbg
        end
        if canUseLvgl then
            settings.useLvgl = fields[24].data.value
        end
        wf.saveSettings(settings)
        wf.reloadMainMenu(true)
        wf.settingsSaved(false, false)
    end,
    title       = "Settings",
    labels      = labels,
    fields      = fields
}
