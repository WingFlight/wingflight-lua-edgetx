local template = wf.executeScript(wf.radio.template)
local margin = template.margin
local indent = template.indent
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local sp = template.listSpacing.field
template = nil
local yMinLim = wf.radio.yMinLimit
local x = margin
local y = yMinLim - lineSpacing
local function incY(val) y = y + val return y end
local labels = {}
local fields = {}
local mspAccTrim = "mspAccTrim"
local data = wf.useApi(mspAccTrim).getDefaults()

labels[#labels + 1] = { t = "Accelerometer Trim", x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Roll",               x = x + indent, y = incY(lineSpacing), sp = x + sp, data = data.roll_trim }
fields[#fields + 1] = { t = "Pitch",              x = x + indent, y = incY(lineSpacing), sp = x + sp, data = data.pitch_trim }

local function receivedData(page)
    wf.onPageReady(page)
end

return {
    read = function(self)
        wf.useApi(mspAccTrim).read(receivedData, self, data)
    end,
    write = function(self)
        if data.roll_trim.value then
            wf.useApi(mspAccTrim).write(data)
            wf.settingsSaved(true, false)
        end
    end,
    title       = "Accelerometer",
    labels      = labels,
    fields      = fields
}
