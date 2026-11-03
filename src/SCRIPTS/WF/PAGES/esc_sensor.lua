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

fields[#fields + 1] = { t = "Pin Swap",                  x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.pin_swap }

incY(lineSpacing * 0.5)
labels[#labels + 1] = { t = "Calibration",              x = x, y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Voltage Correction",       x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.voltage_correction }
fields[#fields + 1] = { t = "Current Correction",       x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.current_correction }
fields[#fields + 1] = { t = "Consumption Correction",   x = x, y = incY(lineSpacing), sp = x + sp, data = escSensorConfig.consumption_correction }



-- SRXL2 ESC bus settings, read after the ESC sensor config. Firmware without
-- the message answers with an MSP error; the section is then dropped from
-- the page before it is shown (it is always the last label and two fields).
local srxl2Config = wf.useApi("mspSrxl2EscConfig").getDefaults()
local srxl2Supported = nil
-- LCD/page.lua re-requests a page that has not loaded within 5 s. Only one
-- SRXL2 read runs at a time, and none once the page is ready, so a late reply
-- cannot overwrite edits made after the page loaded.
local srxl2Reading = false
incY(lineSpacing * 0.5)
labels[#labels + 1] = { t = "SRXL2 ESC",                x = x, y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Telemetry Interval",       x = x, y = incY(lineSpacing), sp = x + sp, data = srxl2Config.telem_interval_frames }
fields[#fields + 1] = { t = "Motor 2 Channel",          x = x, y = incY(lineSpacing), sp = x + sp, data = srxl2Config.motor2_channel }

local function srxl2Unsupported(page)
    srxl2Reading = false
    if srxl2Supported ~= false then
        srxl2Supported = false
        fields[#fields] = nil
        fields[#fields] = nil
        labels[#labels] = nil
    end
    wf.onPageReady(page)
end

local function receivedSrxl2Config(page, _)
    srxl2Reading = false
    srxl2Supported = true
    wf.onPageReady(page)
end

local function receivedEscSensorConfig(page, _)
    if srxl2Reading or page.isReady then return end
    srxl2Reading = true
    wf.useApi("mspSrxl2EscConfig").read(receivedSrxl2Config, page, srxl2Config, srxl2Unsupported)
end

return {
    read = function(self)
        wf.useApi("mspEscSensorConfig").read(receivedEscSensorConfig, self, escSensorConfig)
    end,
    write = function(self)
        if escSensorConfig.protocol.value then
            wf.useApi("mspEscSensorConfig").write(escSensorConfig)
            if srxl2Supported and srxl2Config.motor2_channel.value then
                wf.useApi("mspSrxl2EscConfig").write(srxl2Config)
            end
            wf.settingsSaved(true, true)
        end
    end,
    title       = "ESC Sensor",
    labels      = labels,
    fields      = fields
}
