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
local rules = {}
local selectedRuleIndex = 0

local function setValues(ruleIndex)
    fields[1].data.value = ruleIndex
    fields[2].data = rules[ruleIndex].oper
    fields[3].data = rules[ruleIndex].input
    fields[4].data = rules[ruleIndex].output
    fields[5].data = rules[ruleIndex].offset
    fields[6].data = rules[ruleIndex].weight
    fields[7].data = rules[ruleIndex].weightNeg
    fields[8].data = rules[ruleIndex].speed
    fields[9].data = rules[ruleIndex].curve
    fields[10].data = rules[ruleIndex].condition
end

local function onChangeRule(field, page)
    selectedRuleIndex = field.data.value
    setValues(selectedRuleIndex)
    wf.onPageReady(page)
end

-- Outputs 25 and 26 are reserved: step over them when the value is changed with the
-- wheel (the choice list on LVGL radios doesn't hold them).
local outputBeforeChange = 0

local function onPreEditOutput(field, page)
    outputBeforeChange = field.data.value
end

local function onChangeOutput(field, page)
    local value = field.data.value
    if value >= mspMixer.MIXER_OUTPUT_RESERVED_FIRST and value <= mspMixer.MIXER_OUTPUT_RESERVED_LAST then
        if outputBeforeChange < mspMixer.MIXER_OUTPUT_RESERVED_FIRST then
            value = mspMixer.MIXER_OUTPUT_RESERVED_LAST + 1
        else
            value = mspMixer.MIXER_OUTPUT_RESERVED_FIRST - 1
        end
        field.data.value = value
    end
    outputBeforeChange = value
end

-- `input`/`curve`/`condition` are shown numerically: `input` is the firmware's
-- MIXER_IN_* enum (see Mixer Inputs page), `curve` is 0=none/1..8=Mixer Curves slot,
-- `condition` is 0=always/1..16=Logic Condition slot. `output` is None, Servo 1-24 or
-- Motor 1-4.
labels[#labels + 1] = { t = "Mixer Rules", x = x, y = incY(lineSpacing) }
fields[1] = { t = "Rule",       x = x + indent, y = incY(lineSpacing), sp = x + sp, data = { min = 0, max = mspMixer.MIXER_RULE_COUNT - 1 }, postEdit = onChangeRule }
fields[2] = { t = "Operation",  x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[3] = { t = "Input",      x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[4] = { t = "Output",     x = x + indent, y = incY(lineSpacing), sp = x + sp, preEdit = onPreEditOutput, change = onChangeOutput }
fields[5] = { t = "Offset",     x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[6] = { t = "Weight",     x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[7] = { t = "Weight neg", x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[8] = { t = "Speed",      x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[9] = { t = "Curve",      x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[10] = { t = "Condition", x = x + indent, y = incY(lineSpacing), sp = x + sp }

local function receivedMixerRules(page, receivedRules)
    rules = receivedRules
    setValues(selectedRuleIndex)
    wf.onPageReady(page)
end

return {
    read = function(self)
        mspMixer.getMixerRules(receivedMixerRules, self)
    end,
    write = function(self)
        if rules[0] then
            mspMixer.setMixerRule(selectedRuleIndex, rules[selectedRuleIndex])
            wf.settingsSaved(true, false)
        end
    end,
    title       = "Mixer Rules",
    labels      = labels,
    fields      = fields
}
