local function deleteOrTruncateFile(filepath)
    local file = io.open(filepath, "r")
    if file then
        io.close(file)
        if del then
            -- EdgeTX 2.9+: delete file
            del(filepath)
            return
        end
        -- Older EdgeTX/OpenTX: truncate file
        file = io.open(filepath, "w")
        io.close(file)
    end
end

-- The wftlm mixer script has been incorporated in wfbg.lua and is now stored in WF.
-- Leaving wftlm.lua in MIXES will conflict with wfbg.lua if enabled.
deleteOrTruncateFile("/SCRIPTS/MIXES/wftlm.lua")
deleteOrTruncateFile("/SCRIPTS/MIXES/wftlm.luac")

local i = 1

local function compile()
    script = assert(loadScript("/SCRIPTS/WF/COMPILE/scripts.lua"))(i)
    collectgarbage()
    i = i + 1
    if script then
        lcd.clear()
        lcd.drawText(2, 2, "Compiling...", SMLSIZE)
        lcd.drawText(2, 58, script, SMLSIZE)
        assert(loadScript(script, 'cd')) -- The 'd' flags gets removed in by minimize.lua
        return 0
    end
    local file = io.open("/SCRIPTS/WF/COMPILE/scripts_compiled.lua", 'w')
    io.write(file, "return true")
    io.close(file)
    assert(loadScript("/SCRIPTS/WF/COMPILE/scripts_compiled.lua", 'c'))
    return 1
end

return compile
