local template = wf.executeScript(wf.radio.template)
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
local escSensorConfig = wf.useApi("mspEscSensorConfig").getDefaults()

x = margin
y = yMinLim - tableSpacing.header

fields[#fields + 1] = { t = "Protocol",                  x = x, y = incY(lineSpacing), w = 150, sp = x + sp, data = escSensorConfig.protocol }
fields[#fields + 1] = { t = "Half Duplex",               x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.half_duplex }
--fields[#fields + 1] = { t = "Update Rate",               x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.update_hz }

if wf.apiVersion >= 12.07 then
    fields[#fields + 1] = { t = "Pin Swap",                  x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.pin_swap }
end

if wf.apiVersion >= 12.08 then
    incY(lineSpacing * 0.5)
    labels[#labels + 1] = { t = "Calibration",              x = x, y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Voltage Correction",       x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.voltage_correction }
    fields[#fields + 1] = { t = "Current Correction",       x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.current_correction }
    fields[#fields + 1] = { t = "Consumption Correction",   x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.consumption_correction }
end

if wf.apiVersion < 12.09 then
    incY(lineSpacing * 0.5)
    labels[#labels + 1] = { t = "HW V4 specific",           x = x, y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "HW V4 Current Offset",     x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.hw4_current_offset }
    fields[#fields + 1] = { t = "HW V4 Current Gain",       x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.hw4_current_gain }
    fields[#fields + 1] = { t = "HW V4 Voltage Gain",       x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.hw4_voltage_gain }
end


local function receivedEscSensorConfig(page, _)
    wf.onPageReady(page)
end

return {
    read = function(self)
        wf.useApi("mspEscSensorConfig").read(receivedEscSensorConfig, self, escSensorConfig)
    end,
    write = function(self)
        if escSensorConfig.protocol.value then
            wf.useApi("mspEscSensorConfig").write(escSensorConfig)
            wf.settingsSaved(true, true)
        end
    end,
    title       = "ESC Sensor",
    labels      = labels,
    fields      = fields
}
