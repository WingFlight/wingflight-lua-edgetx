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
local modelName = "---"
local flighStats = wf.useApi("mspFlightStats").getDefaults()
local pilotConfig = wf.useApi("mspPilotConfig").getDefaults()
local setNameOnTxFieldIndex

local function buildForm(page)
    page.labels = nil
    page.fields = nil
    labels = {}
    fields = {}
    collectgarbage()

    x = margin
    y = yMinLim - tableSpacing.header

    labels[#labels + 1] = { t = modelName,      x = x, y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Model ID",     x = x, y = incY(lineSpacing), sp = x + sp, data = pilotConfig.model_id }

    if wf.apiVersion >= 12.09 then
        incY(lineSpacing * 0.5)
        labels[#labels + 1] = { t = "Statistics",         x = x, y = incY(lineSpacing) }
        fields[#fields + 1] = { t = "Enabled",            x = x, y = incY(lineSpacing), sp = x + sp, data = flighStats.statsEnabled,
            postEdit = function(self, page)
                if self.data.value == 0 then
                    flighStats.stats_min_armed_time_s.value = -1   -- stats disabled
                else
                    flighStats.stats_min_armed_time_s.value = 15   -- >= 15s armed counts as a flight
                end
                buildForm(page)
                wf.onPageReady(page)
            end
        }

        if flighStats.statsEnabled.value and flighStats.statsEnabled.value == 1 then
            fields[#fields + 1] = { t = "Total flights",  x = x, y = incY(lineSpacing), sp = x + sp, data = flighStats.stats_total_flights, readOnly = true }
            local totalTime = wf.executeScript("F/formatSeconds")(flighStats.stats_total_time_s.value)
            fields[#fields + 1] = { t = "Total time",     x = x, y = incY(lineSpacing), sp = x + sp, data = { value = totalTime }, readOnly = true  }

            fields[#fields + 1] = { t = "Total distance", x = x, y = incY(lineSpacing), sp = x + sp, data = flighStats.stats_total_dist_m, readOnly = true  }
            fields[#fields + 1] = { t = "Min armed time", x = x, y = incY(lineSpacing), sp = x + sp, data = flighStats.stats_min_armed_time_s }

            local function resetStats(self, page)
                flighStats.stats_total_flights.value = 0
                flighStats.stats_total_time_s.value = 0
                flighStats.stats_total_dist_m.value = 0
                buildForm(page)
                wf.onPageReady(page)
            end
            fields[#fields + 1] = { t = "[Reset]",  x = x + indent * 3, y = incY(lineSpacing * 1.3), preEdit = resetStats }
        end
    end

    incY(lineSpacing * 0.5)
    labels[#labels + 1] = { t = "Radio Configuration",       x = x, y = incY(lineSpacing) }
    if not wf.widget then
        labels[#labels + 1] = { t = "Note: requires wfbg",   x = x + indent, y = incY(lineSpacing), bold = false }
    end

    local function getAutoSetName()
        if wf.apiVersion >= 12.07 and wf.apiVersion < 12.09 then
            return settings.autoSetName or 0
        end
        local getBit = wf.executeScript("F/getBit")
        return getBit(pilotConfig.model_flags.value, pilotConfig.model_flags.MODEL_SET_NAME) or 0
    end
    incY(lineSpacing * 0.25)
    setNameOnTxFieldIndex = #fields + 1
    fields[setNameOnTxFieldIndex] = { t = "Set name on TX", x = x, y = incY(lineSpacing), sp = x + sp, data = { value = getAutoSetName() or 0, min = 0, max = 1, table = { [0] = "Off", "On" } } }

    incY(lineSpacing * 0.25)
    fields[#fields + 1] = { t = "Param1 type",  x = x, y = incY(lineSpacing), sp = x + sp, data = pilotConfig.model_param1_type }
    fields[#fields + 1] = { t = "Param1 value", x = x, y = incY(lineSpacing), sp = x + sp, data = pilotConfig.model_param1_value }
    fields[#fields + 1] = { t = "Param2 type",  x = x, y = incY(lineSpacing), sp = x + sp, data = pilotConfig.model_param2_type }
    fields[#fields + 1] = { t = "Param2 value", x = x, y = incY(lineSpacing), sp = x + sp, data = pilotConfig.model_param2_value }
    fields[#fields + 1] = { t = "Param3 type",  x = x, y = incY(lineSpacing), sp = x + sp, data = pilotConfig.model_param3_type }
    fields[#fields + 1] = { t = "Param3 value", x = x, y = incY(lineSpacing), sp = x + sp, data = pilotConfig.model_param3_value }

    page.labels = labels
    page.fields = fields
end

local function onReceivedModelName(page, name)
    modelName = name
end

local function onReceivedPilotConfig(page, config)
    buildForm(page)
    wf.onPageReady(page)
    if wf.resetPilotConfig then
        -- Deferred execution needed when running as a widget,
        -- because wf.mspQueue:clear() will be called on reset.
        wf.executeScript("F/pilotConfigReset")()
        wf.resetPilotConfig = nil
    end
end

local function setAutoSetName()
    local autoSetName = fields[setNameOnTxFieldIndex].data.value
    if wf.apiVersion >= 12.07 and wf.apiVersion < 12.09 then
        settings.autoSetName = autoSetName
        wf.saveSettings(settings)
        return
    end

    local setBit = wf.executeScript("F/setBit")
    pilotConfig.model_flags.value = setBit(pilotConfig.model_flags.value, pilotConfig.model_flags.MODEL_SET_NAME, autoSetName)
end

return {
    read = function(self)
        wf.useApi("mspName").getModelName(onReceivedModelName, self)
        if wf.apiVersion >= 12.09 then
            wf.useApi("mspFlightStats").read(nil, nil, flighStats)
        end
        wf.useApi("mspPilotConfig").read(onReceivedPilotConfig, self, pilotConfig)
    end,
    write = function(self)
        setAutoSetName()
        if wf.apiVersion >= 12.09 then
            wf.useApi("mspFlightStats").write(flighStats)
        end
        wf.useApi("mspPilotConfig").write(pilotConfig)
        wf.resetPilotConfig = true
        wf.settingsSaved(true, false)
    end,
    title       = "Model",
    labels      = labels,
    fields      = fields
}
