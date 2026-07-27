local template = wf.executeScript(wf.radio.template)
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
local inputs = {}
local selectedInputIndex = 0

local function setValues(inputIndex)
    fields[1].data.value = inputIndex
    fields[2].data = inputs[inputIndex].rate
    fields[3].data = inputs[inputIndex].min
    fields[4].data = inputs[inputIndex].max
end

local function onChangeInput(field, page)
    selectedInputIndex = field.data.value
    setValues(selectedInputIndex)
    wf.onPageReady(page)
end

-- Input index is the firmware's MIXER_IN_* enum (0=None, 1-4=Stabilized Roll/Pitch/Yaw/
-- Throttle, 5-8=RC Command Roll/Pitch/Yaw/Throttle, 9-26=RC Channel Roll/Pitch/Yaw/
-- Throttle/Aux1-3/8-18) -- shown numerically here since the exact channel-to-servo/motor
-- mapping is board/target specific and not worth guessing labels for.
labels[#labels + 1] = { t = "Mixer Inputs", x = x, y = incY(lineSpacing) }
fields[1] = { t = "Input",  x = x + indent, y = incY(lineSpacing), sp = x + sp, data = { min = 0, max = mspMixer.MIXER_INPUT_COUNT - 1 }, postEdit = onChangeInput }
fields[2] = { t = "Rate",   x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[3] = { t = "Min",    x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[4] = { t = "Max",    x = x + indent, y = incY(lineSpacing), sp = x + sp }

local function receivedMixerInputs(page, receivedInputs)
    inputs = receivedInputs
    setValues(selectedInputIndex)
    wf.onPageReady(page)
end

return {
    read = function(self)
        mspMixer.getMixerInputs(receivedMixerInputs, self)
    end,
    write = function(self)
        if inputs[0] then
            mspMixer.setMixerInput(selectedInputIndex, inputs[selectedInputIndex])
            wf.settingsSaved(true, false)
        end
    end,
    title       = "Mixer Inputs",
    labels      = labels,
    fields      = fields
}
