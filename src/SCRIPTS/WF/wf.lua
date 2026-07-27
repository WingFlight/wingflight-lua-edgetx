wf = {
    luaVersion = "2.3.0",
    baseDir = "/SCRIPTS/WF/",
    runningInSimulator = string.sub(select(2, getVersion()), -4) == "simu",

    loadScript = function(script)
        local startsWith = function(str, prefix)
            return string.sub(str, 1, #prefix) == prefix
        end
        local endsWith = function(str, suffix)
            return suffix == "" or string.sub(str, -#suffix) == suffix
        end
        if not startsWith(script, wf.baseDir) then
            script = wf.baseDir .. script
        end
        if not endsWith(script, ".lua") then
            script = script .. ".lua"
        end
        collectgarbage()
        local result = loadScript(script)
        --wf.showMemoryUsage(script .. " loaded")
        return result
    end,

    executeScript = function(scriptName, ...)
        return assert(wf.loadScript(scriptName), scriptName)(...)
    end,

    useApi = function(apiName)
        return wf.executeScript("MSP/" .. apiName)
    end,

    loadSettings = function()
        return wf.executeScript("PAGES/helpers/settingsHelper").loadSettings();
    end,

    saveSettings = function(settings)
        return wf.executeScript("PAGES/helpers/settingsHelper").saveSettings(settings);
    end,

    clock = function()
        return getTime() / 100
    end,

    isEdgeTx = select(6, getVersion()) == "EdgeTX",

    apiVersion = nil,

    units = {
        percentage = "%",
        degrees = del and "°" or "@", -- OpenTX uses @
        degreesPerSecond = (del and "°" or "@") .. "/s",
        herz = " Hz",
        seconds = " s",
        milliseconds = " ms",
        volt = " V",
        celsius = " C",
        rpm = " RPM",
        meters = " m",
        mah = " mAh",
        percentagePerSecond = " %/s",
        millivoltsPerSecond = " mV/s",
        khz = " kHz",
        kv = " KV"
    },

    --[NIR
    formatTime = function(cs)
        local hours = math.floor(cs / 360000)
        cs = cs % 360000

        local minutes = math.floor(cs / 6000)
        cs = cs % 6000

        local seconds = math.floor(cs / 100)
        local centis = cs % 100

        return string.format("%02d:%02d:%02d:%02d", hours, minutes, seconds, centis)
    end,

    print = function(format, ...)
        local str = string.format("%s - WF: " .. tostring(format), wf.formatTime(getTime()), ...)
        if wf.runningInSimulator then
            print(str)
        else
            serialWrite(str .. "\r\n") -- 115200 bps
            --wf.log(str)
        end
    end,

    log = function(str)
        if wf.runningInSimulator then
            wf.print(tostring(str))
        else
            if not wf.logfile then
                wf.logfile = io.open("/LOGS/wf.log", "a")
            end
            io.write(wf.logfile, string.format("%.2f ", wf.clock()) .. tostring(str) .. "\n")
        end
    end,

    showMemoryUsage = function(remark)
        if not wf.oldMemoryUsage then
            collectgarbage()
            wf.oldMemoryUsage = collectgarbage("count")
            wf.print(string.format("MEM %s: %d", remark, wf.oldMemoryUsage*1024))
            return
        end
        collectgarbage()
        local currentMemoryUsage = collectgarbage("count")
        local increment = currentMemoryUsage - wf.oldMemoryUsage
        if increment ~= 0 then
            wf.print(string.format("MEM %s: %d (+%d)", remark, currentMemoryUsage*1024, increment*1024))
        end
        wf.oldMemoryUsage = currentMemoryUsage
    end,

    dumpTable = function(table, maxDepth)
        local seen = {}
        maxDepth = maxDepth or 2

        local function dumpTableInternal(tbl, indent, depth)
            if seen[tbl] or depth > maxDepth then
                wf.print(indent .. "*already visited or max depth*")
                return
            end
            seen[tbl] = true

            for k, v in pairs(tbl) do
                local keyStr = tostring(k)
                local vType = type(v)
                if vType == "table" then
                    wf.print(indent .. keyStr .. " = {")
                    dumpTableInternal(v, indent .. "  ", depth + 1)
                    wf.print(indent .. "}")
                else
                    wf.print(indent .. keyStr .. " = " .. tostring(v))
                end
            end
        end

        dumpTableInternal(table, "", 0)
    end,

    printGlobals = function(maxDepth)
        wf.dumpTable(_G, maxDepth)
    end,

    isInteger = function(n)
        return type(n) == "number" and n == math.floor(n)
    end,
    --]]

    call = function(func, ...)
        -- NOTE: 'wf.call' will be replaced by 'pcall' in release builds, see minimize.lua.
        -- This is done so all integration calls are protected.

        -- Use unprotected calls during development, so errors surface immediately.
        func(...)

        -- Or use protected calls and show any errors afterwards.
        -- local status, err = pcall(func, ...)
        -- if not status then wf.print(err) end
    end
}
