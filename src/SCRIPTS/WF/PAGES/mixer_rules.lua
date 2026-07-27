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

-- `input`/`output`/`curve`/`condition` are shown numerically: `input` is the firmware's
-- MIXER_IN_* enum (see Mixer Inputs page), `output` is 0=none then servo outputs then
-- motor outputs (board/target specific count), `curve` is 0=none/1..8=Mixer Curves slot,
-- `condition` is 0=always/1..16=Logic Condition slot.
labels[#labels + 1] = { t = "Mixer Rules", x = x, y = incY(lineSpacing) }
fields[1] = { t = "Rule",       x = x + indent, y = incY(lineSpacing), sp = x + sp, data = { min = 0, max = mspMixer.MIXER_RULE_COUNT - 1 }, postEdit = onChangeRule }
fields[2] = { t = "Operation",  x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[3] = { t = "Input",      x = x + indent, y = incY(lineSpacing), sp = x + sp }
fields[4] = { t = "Output",     x = x + indent, y = incY(lineSpacing), sp = x + sp }
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
