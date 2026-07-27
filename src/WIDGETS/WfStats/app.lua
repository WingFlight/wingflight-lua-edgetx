-- This WfStats widget demonstrates how to:
-- * register a widget with WfTool using wf.registerWidget()
-- * receive model state changes using onStateChanged()
-- * use MSP to retrieve data from the flight controller using wf.useApi()

local zone, options = ...

local w = {
    zone = zone,
    options = options
}

local totalFlights = nil
local totalFlightTime = nil

local function getTotalFlights()
    return "Flights: " .. (totalFlights or "")
end

local function getTotalTime()
    return "Total flight time: " .. (totalFlightTime or "")
end

local function showWidget(widget)
    lvgl.clear();
    lvgl.build({
        {
            type = "box", flexFlow = lvgl.FLOW_COLUMN, children =
            {
                { type = "label", text = function() return getTotalFlights() end, w = widget.zone.x, align = CENTER },
                { type = "label", text = function() return getTotalTime() end, w = widget.zone.x, align = CENTER },
            }
        }
    });
end

w.update = function(widget, options)
    -- Called when the widget options or size change.
    widget.options = options
    showWidget(widget)
end

w.background = function(widget)
    -- Called when the widget isn't visible.
    if wf and not widget.isRegistered then
        wf.registerWidget(widget)
        widget.isRegistered = true
    end
end

w.refresh = function(widget, event, touchState)
    -- Called when the widget is visible.
    w.background(widget)
end

local function onReceivedFlightStats(callbackParam, stats)
    -- See SCRIPTS/WF/MSP/mspFlightStats.lua for all keys in stats
    totalFlights = tostring(stats.stats_total_flights.value)
    totalFlightTime = wf.executeScript("F/formatSeconds")(stats.stats_total_time_s.value)
end

w.onStateChanged = function(widget, newState)
    -- Called by WfTool when the widget is registered and the model state changes.
    --   newState can be: "connected", "disconnected", "armed" or "disarmed".
    -- Note:  WfTool requires the 'ARM' sensor for setting "armed" and "disarmed".

    --wf.print("newState: %s", newState)
    if newState == "connected" or newState == "disarmed" then
        wf.useApi("mspFlightStats").read(onReceivedFlightStats, "unused example callback parameter")
    elseif newState == "disconnected" then
        totalFlights = nil
        totalFlightTime = nil
    end
end

return w
