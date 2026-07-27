local lcdShared = wf.executeScript("LCD/shared")
local waitMessage = wf.executeScript("LCD/waitMessage", lcdShared)
local messageBox = nil -- loaded on demand
local popupMenu = nil  -- loaded on demand
local Page = nil       -- loaded on demand
local mainMenu = nil   -- loaded on demand

local PageFiles
local CurrentPageIndex = 1

local uiStatus =
{
    init     = 1,
    mainMenu = 2,
    pages    = 3,
    confirm  = 4,
}

local uiState = uiStatus.init
local prevUiState
local pageState = lcdShared.pageStatus.display
local saveTS = 0
local init
local clearQueue = false

-- Color radios on EdgeTX >= 2.11 do not send EVT_VIRTUAL_ENTER anymore after EVT_VIRTUAL_ENTER_LONG
local useKillEnterBreak = not(lcd.setColor and (select(3, getVersion()) >= 3 or select(3, getVersion()) >= 2 and select(4, getVersion()) >= 11))

wf.setWaitMessage = function(message)
    waitMessage.text = message
end

wf.clearWaitMessage = function()
    waitMessage.text = nil
end

local function invalidatePages()
    Page = nil
    pageState = lcdShared.pageStatus.display
    wf.clearWaitMessage()
end

wf.onPageReady = function(page)
    page.isReady = true
    wf.lcdNeedsInvalidate = true
end

local function rebootFc()
    --wf.print("Attempting to reboot the FC...")
    wf.setWaitMessage("Rebooting...")
    pageState = lcdShared.pageStatus.rebooting
    wf.mspQueue:add({
        command = 68, -- MSP_REBOOT
        processReply = function(self, buf)
            invalidatePages()
        end,
        simulatorResponse = {}
    })
end

local function createMessageBox(title, text)
    messageBox = wf.executeScript("LCD/messageBox", lcdShared)
    messageBox.show(title, text)
end

wf.settingsSaved = function(eepromWrite, reboot)
    -- check if this page requires writing to eeprom to save (most do)
    if eepromWrite then
        -- don't write again if we're already responding to earlier page.write()s
        if pageState ~= lcdShared.pageStatus.eepromWrite then
            pageState = lcdShared.pageStatus.eepromWrite
            local mspEepromWrite =
            {
                command = 250, -- MSP_EEPROM_WRITE, fails when armed
                processReply = function(self, buf)
                    if reboot then
                        rebootFc()
                    else
                        invalidatePages()
                    end
                end,
                errorHandler = function(self)
                    if wf.apiVersion >= 12.08 then
                        if not wf.saveWarningShown then
                            createMessageBox("Save warning", "Settings will be saved\nafter disarming.")
                            wf.saveWarningShown = true
                        else
                            invalidatePages()
                        end
                    else
                        createMessageBox("Save error", "Make sure your heli\nis disarmed.")
                    end
                end,
                simulatorResponse = {}
            }
            wf.mspQueue:add(mspEepromWrite)
        end
    elseif pageState ~= lcdShared.pageStatus.eepromWrite then
        -- If we're not already trying to write to eeprom from a previous save, then we're done.
        invalidatePages()
    end
end

local function saveSettings()
    if pageState ~= lcdShared.pageStatus.saving then
        wf.setWaitMessage("Updating...")
        pageState = lcdShared.pageStatus.saving
        saveTS = wf.clock()
        Page:write()
    end
end

local function confirm(page)
    prevUiState = uiState
    uiState = uiStatus.confirm
    invalidatePages()
    Page = wf.executeScript(page)
    Page.lcdp = wf.executeScript("LCD/page", lcdShared, Page)
end

local function createPopupMenu()
    local menu = { title = "Menu:", items = {} }

    if uiState == uiStatus.pages then
        if not Page.readOnly then
            menu.items[#menu.items + 1] = { text = "Save", click = saveSettings }
        end
        menu.items [#menu.items + 1] = { text = "Reload", click = invalidatePages }
    end

    menu.items[#menu.items + 1] = { text = "Reboot", click = rebootFc }
    menu.items[#menu.items + 1] = { text = "Acc Cal", click = function() confirm("CONFIRM/acc_cal.lua") end }

    popupMenu = wf.executeScript("LCD/popupMenu", lcdShared)
    popupMenu.show(menu)
end

local function incPage(inc)
    if Page and Page.unload then
        Page:unload()
    else
        clearQueue = true
    end
    CurrentPageIndex = wf.executeScript("F/incMax")(CurrentPageIndex, inc, #PageFiles)
    invalidatePages()
end

local function reloadPageFiles(setCurrentPageToLastPage)
    PageFiles = wf.executeScript("pages")
    if setCurrentPageToLastPage then
        CurrentPageIndex = #PageFiles
    end
end

local function run_ui(event)
    -- if event and event ~= 0 then
    --     wf.print("uiState: " .. uiState .. " pageState: " .. pageState .. " Event: " .. string.format("0x%X", event))
    -- end

    if messageBox and messageBox.update(event) then
        if lcdShared.forceReload then
            messageBox = nil
            invalidatePages()
        end
    elseif popupMenu and popupMenu.update(event) then
        if popupMenu.menu == nil then
            popupMenu = nil
        end
    elseif uiState == uiStatus.init then
        lcd.clear()
        lcdShared.drawScreenTitle("WingFlight " .. wf.luaVersion)
        init = init or wf.executeScript("ui_init")
        lcdShared.drawTextMultiline(4, wf.radio.yMinLimit, init.t)
        if not init.f() then
            return 0
        end
        init = nil
        reloadPageFiles()
        invalidatePages()
        uiState = prevUiState or uiStatus.mainMenu
        prevUiState = nil
    elseif uiState == uiStatus.mainMenu then
        if not mainMenu then
            mainMenu = wf.executeScript("LCD/mainMenu", lcdShared, PageFiles, CurrentPageIndex)
        end
        if event == EVT_VIRTUAL_EXIT then
            return 2
        elseif event == EVT_VIRTUAL_ENTER then
            CurrentPageIndex = mainMenu.getSelectedPageIndex()
            uiState = uiStatus.pages
        elseif event == EVT_VIRTUAL_ENTER_LONG then
            if useKillEnterBreak then lcdShared.killEnterBreak = true end
            createPopupMenu()
        else
            mainMenu.update(event)
        end
    elseif uiState == uiStatus.pages then
        mainMenu = nil
        if Page then
            pageState = Page.lcdp.update(pageState, event)
        end

        if pageState == lcdShared.pageStatus.saving then
            if saveTS + 5.0 <= wf.clock() then
                --wf.print("Save timeout!")
                invalidatePages()
            end
        elseif pageState == lcdShared.pageStatus.display then
            if event == EVT_VIRTUAL_PREV_PAGE then
                incPage(-1)
                killEvents(event) -- X10/T16 issue: pageUp is a long press
            elseif event == EVT_VIRTUAL_NEXT_PAGE then
                incPage(1)
            elseif event == EVT_VIRTUAL_ENTER_LONG then
                if useKillEnterBreak then lcdShared.killEnterBreak = true end
                createPopupMenu()
            elseif event == EVT_VIRTUAL_EXIT then
                if Page and Page.unload then Page:unload() end
                invalidatePages()
                uiState = uiStatus.mainMenu
                if wf.logfile then
                    io.close(wf.logfile)
                    wf.logfile = nil
                end
                return 0
            end
        end
        if not Page then
            if clearQueue then
                -- Only clear queue when the current page has changed, and not when saving a page.
                clearQueue = false
                wf.mspQueue:clear()
            end
            --wf.showMemoryUsage("before loading page")
            Page = wf.executeScript("PAGES/" .. PageFiles[CurrentPageIndex].script)
            Page.lcdp = wf.executeScript("LCD/page", lcdShared, Page)
            --wf.showMemoryUsage("after loading page")
        end
    elseif uiState == uiStatus.confirm then
        Page.lcdp.draw(pageState)
        if event == EVT_VIRTUAL_ENTER then
            uiState = uiStatus.init
            init = Page.init
            invalidatePages()
        elseif event == EVT_VIRTUAL_EXIT then
            invalidatePages()
            uiState = prevUiState
            prevUiState = nil
        end
    end

    waitMessage.update()

    if getRSSI() == 0 then
        lcd.drawText(wf.radio.NoTelem[1], wf.radio.NoTelem[2], wf.radio.NoTelem[3], wf.radio.NoTelem[4])
    end

    wf.mspQueue:processQueue()

    return 0
end

wf.reloadPage = invalidatePages
wf.reloadMainMenu = reloadPageFiles

return run_ui
