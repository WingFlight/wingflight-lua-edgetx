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
local mixerConfig = wf.useApi("mspMixer").getDefaults()

labels[#labels + 1] = { t = "Mixer",     x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Airframe",  x = x + indent, y = incY(lineSpacing), sp = x + sp, data = mixerConfig.model_type }

incY(lineSpacing * 0.5)
labels[#labels + 1] = { t = "Note: pick \"Custom\" to edit raw mixer inputs, rules and", x = x, y = incY(lineSpacing), bold = false }
labels[#labels + 1] = { t = "curves directly via the Mixer Inputs / Mixer Rules pages.", x = x, y = incY(lineSpacing), bold = false }

local function receivedMixerConfig(page, _)
    wf.onPageReady(page)
end

return {
    read = function(self)
        wf.useApi("mspMixer").read(receivedMixerConfig, self, mixerConfig)
    end,
    write = function(self)
        if mixerConfig.model_type.value then
            wf.useApi("mspMixer").write(mixerConfig)
            wf.settingsSaved(true, false)
        end
    end,
    title       = "Mixer",
    labels      = labels,
    fields      = fields
}
