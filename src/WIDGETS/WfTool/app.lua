---@diagnostic disable: undefined-global
-- WfTool widget
local zone, options = ...

local w = {
    zone = zone,
    options = options
}

local warningDuplicate = wf ~= nil and wf.wfToolInstanceSeenAt ~= nil and wf.clock() - wf.wfToolInstanceSeenAt <= 1

local fontTools = assert(loadScript("/SCRIPTS/WF/F/fontTools.lua"))()

local scriptsCompiled = assert(loadScript("/SCRIPTS/WF/COMPILE/scripts_compiled.lua"))()
if scriptsCompiled then
    w.state = "loading"
else
    w.state = "compiling"
end

local function getTelemetryText(options, measure)
    local source = options.sourceName
    if not source or source == "" then return "No source" end

    if measure then
        if #source < 4 then
            source = string.rep("W", 4 - #source) .. source
        end
        return source .. ": 0000" .. options.sourceUnit
    end

    -- Not available at boot time
    if not getValue then return source .. ":" end

    local value = getValue(source)
    if value == nil then return source .. ": -" end

    return source .. ": " .. tostring(value) .. options.sourceUnit
end

w.options.getText = function(options)
    if not options.sourceName then return "" end
    if not getValue then return " - " .. options.sourceName .. ": " end
    return " - " .. options.sourceName .. ": " .. tostring(getValue(options.sourceName)) .. options.sourceUnit
end

local compileTask = nil
local uiTask = nil
local backgroundTask = nil

local timeCreated = getTime()

local wfWidgets = {}
local function registerWidget(widget)
    table.insert(wfWidgets, widget)
end

local function publishStateChangedEvent(newState)
    for k, v in pairs(wfWidgets) do
        if v.onStateChanged then
            wf.call(v.onStateChanged, v, newState)
        end
    end
end

local previousArmState = 0
local function setArmState(widget)
    if not getValue then return end -- not available at boot time
    local armState = getValue("ARM")
    --[NIR
    -- Use ANT instead of ARM in the simulator
    if wf and wf.runningInSimulator then armState = getValue("ANT") end
    --]]
    if armState ~= previousArmState then
        previousArmState = armState
        local state = bit32.btest(armState, 1) and "armed" or "disarmed"
        widget:setState(state)
    end
end

w.setState = function(self, state)
    -- This function will also be called from the background task
    if self.state == state then return end
    self.state = state
    if state == "disconnected" then
        wf.modelName = nil
        previousArmState = 0
    end
    publishStateChangedEvent(self.state)
end

local function initializeWfGlobalVar()
    -- wf is the *only* global variable that is used by the WingFlight scripts.
    --print("WF: Before wf.lua: ", collectgarbage("count") * 1024)
    assert(loadScript("/SCRIPTS/WF/wf.lua"))()
    --wf.showMemoryUsage("wf loaded")
end

local function loadScripts(widget)
    -- load required scripts
    wf.radio = wf.executeScript("radios")
    wf.mspQueue = wf.executeScript("MSP/mspQueue")
    wf.mspHelper = wf.executeScript("MSP/mspHelper")

    -- load tasks
    uiTask = wf.executeScript("ui_lvgl_runner")
    backgroundTask = wf.executeScript("background")
end

local function getModelName()
    local modelName = wf and wf.modelName or nil

    if not modelName then
         modelName = model.getInfo().name
    end

    return modelName or "Unknown"
end

local function getStateText(widget)
    local state = widget.state
    return string.upper(string.sub(state, 1, 1)) .. string.sub(state, 2)
end

local function getDisplayedModelName(widget)
    if widget.options["Hide Model"] == 1 then return nil end
    return getModelName()
end

local function showWidget(widget)
    local STATE_MEASURE_TEXT = "Unknown Protocol"  -- Longest possible state string

    local widgetW = widget.zone.w or widget.zone.x
    local widgetH = widget.zone.h or widget.zone.y
    local displayedModelName = getDisplayedModelName(widget)
    local showModel = displayedModelName ~= nil
    local showState = widget.options["Hide State"] ~= 1
    local showTelemetry = widget.options["Hide Telemetry"] ~= 1
    local telemetryMeasure = showTelemetry and getTelemetryText(widget.options, true) or nil
    local row1Text = nil
    local row1Measure = nil
    local row2Text = nil
    local row2Measure = nil
    local textColor = widget.options.Color or COLOR_THEME_PRIMARY1

    -- Determine what text to show in row 1 and row 2 based on the options
    if showModel then
        row1Text = displayedModelName
        row1Measure = displayedModelName
    end

    if showState and showTelemetry then
        if row1Text then
            row2Text = function()
                return getStateText(widget) .. " - " .. getTelemetryText(widget.options)
            end
            row2Measure = STATE_MEASURE_TEXT .. " - " .. telemetryMeasure
        else
            row1Text = function() return getStateText(widget) end
            row1Measure = STATE_MEASURE_TEXT
            row2Text = function() return getTelemetryText(widget.options) end
            row2Measure = telemetryMeasure
        end
    elseif showState then
        if row1Text then
            row2Text = function() return getStateText(widget) end
            row2Measure = STATE_MEASURE_TEXT
        else
            row1Text = function() return getStateText(widget) end
            row1Measure = STATE_MEASURE_TEXT
        end
    elseif showTelemetry then
        if row1Text then
            row2Text = function() return getTelemetryText(widget.options) end
            row2Measure = telemetryMeasure
        else
            row1Text = function() return getTelemetryText(widget.options) end
            row1Measure = telemetryMeasure
        end
    end

    if warningDuplicate then
        row1Text = "Warning"
        row1Measure = row1Text
        row2Text = "Use only one WF Tool widget"
        row2Measure = row2Text
        textColor = COLOR_THEME_WARNING
    end

    local children = {}

    if row1Text then
        -- Build the lvgl object tree. If no rows are enabled we leave
        -- children empty, which clears the widget while still flowing through
        -- the same render tail.
        local padX = 2
        local padY = 2
        local rowGap = 1
        local contentW = math.max(1, widgetW - 2 * padX)
        local contentH = math.max(1, widgetH - 2 * padY)

        if row2Text then
            local topH = math.max(1, math.floor((contentH - rowGap + 1) / 2))
            local topFont = fontTools.selectFont(topH, contentW, row1Measure)
            local topFontH = fontTools.measureFont(topFont)
            local detailH = math.max(1, contentH - topFontH - rowGap)
            local detailFont = fontTools.selectFont(detailH, contentW, row2Measure, topFont)
            local detailFontH = fontTools.measureFont(detailFont)
            local detailY = padY + topFontH + rowGap

            children[#children + 1] = {
                type = "label",
                x = padX,
                y = padY,
                w = contentW,
                h = topFontH,
                text = row1Text,
                font = topFont,
                color = textColor,
                align = LEFT
            }
            children[#children + 1] = {
                type = "label",
                x = padX,
                y = detailY,
                w = contentW,
                h = detailFontH,
                text = row2Text,
                font = detailFont,
                color = textColor,
                align = LEFT
            }
        else
            local rowFont = fontTools.selectFont(contentH, contentW, row1Measure)
            local rowFontH = fontTools.measureFont(rowFont)
            local rowY = padY + math.max(0, math.floor((contentH - rowFontH) / 2))

            children[#children + 1] = {
                type = "label",
                x = padX,
                y = rowY,
                w = contentW,
                h = rowFontH,
                text = row1Text,
                font = rowFont,
                color = textColor,
                align = LEFT
            }
        end
    end

    lvgl.clear()
    lvgl.build(children)

    widget.renderedModelName = displayedModelName
    widget.visible = true
end

w.update = function(widget, options)
    widget.options = options
    if options and options.Source and getFieldInfo then
        local fieldInfo = getFieldInfo(options.Source)
        if fieldInfo then
            widget.options.sourceName = fieldInfo.name
            widget.options.sourceUnit = wf.executeScript("F/sensorTools").getUnitSymbol(fieldInfo.unit)
        end
    end

    if warningDuplicate then
        showWidget(widget)
        return
    end

    if lvgl.isFullScreen() or lvgl.isAppMode() then
        wf.restartUi()
    else
        showWidget(widget)
    end
end

w.background = function(widget, calledFromRefresh)
    if warningDuplicate then
        return
    end

    wf.wfToolInstanceSeenAt = wf.clock()

    if widget.state == "compiling" then
        compileTask = compileTask or assert(loadScript("/SCRIPTS/WF/COMPILE/compile.lua"))()
        if compileTask() == 1 then
            compileTask = nil
            widget.state = "loading"
        end
        return
    elseif widget.state == "loading"
        and (getTime() - timeCreated) / 100 > 1 -- bootgrace timeout
    then
        if not wf.widget then
            wf.widget = widget
        end
        widget.state = "unknown protocol"
    elseif widget.state == "unknown protocol" then
        local protocol = wf.executeScript("F/getProtocol")()
        if protocol then
            loadScripts(widget)
            widget.state = "ready"
        end
    end

    setArmState(widget)

    if not calledFromRefresh then
        widget.visible = false
        if uiTask then
            -- uiTask also handles mspQueue in the background, so make sure to call it
            -- even when the widget isn't visible.
            uiTask()
        end
    end

    if backgroundTask then
        backgroundTask(widget)
    end
end

local redrawWidget = false
w.refresh = function(widget, event, touchState)
    if warningDuplicate then
        if not widget.visible then
            showWidget(widget)
        end
        return
    end

    if uiTask ~= nil then
        if redrawWidget or not widget.visible or widget.renderedModelName ~= getDisplayedModelName(widget) then
            -- If we immediately show the widget after lvgl.exitFullScreen(), the widget if briefly
            -- displayed in full screen mode. Using redrawWidget prevents that.
            showWidget(widget)
            redrawWidget = false
        end

        local noUi = not(lvgl.isFullScreen() or lvgl.isAppMode())
        local result = uiTask(event, touchState, noUi)
        if lvgl.isFullScreen() and result == 2 then
            lvgl.exitFullScreen()
            redrawWidget = true
        end
    end

    w.background(widget, true)
end

if warningDuplicate then
    -- Duplicate instances stay warning-only so they do not reinitialize shared WF state.
    return w
end

initializeWfGlobalVar()
wf.wfToolInstanceSeenAt = wf.clock()
wf.registerWidget = registerWidget
wf.wfToolApiVersion = 1.00

return w
