local rateSwitcher = {
    mspStatus = wf.executeScript("MSP/mspStatus"),
    editing = false,
    rateAdjustmentTS = nil,

    getStatus = function(page)
        local self = page.rateSwitcher
        self.mspStatus.getStatus(self.onProcessedMspStatus, page)
    end,

    checkStatus = function(page)
        local self = page.rateSwitcher
        if self.rateAdjustmentTS and wf.clock() - self.rateAdjustmentTS > 0.5 then
            wf.reloadPage()
        elseif wf.mspQueue:isProcessed() and not self.editing then
            self.mspStatus.getStatus(self.onProcessedMspStatus, page)
        end
    end,

    onProcessedMspStatus = function(page, status)
        local self = page.rateSwitcher
        local currentField = page.fields[1]
        if currentField.data.value ~= status.rateProfile and not page.rateSwitcher.editing then
            if currentField.data.value then
                page.rateSwitcher.rateAdjustmentTS = wf.clock()
            end
            currentField.data.value = status.rateProfile
            wf.lcdNeedsInvalidate = true
        end

        page.isReady = true
    end,

    startPidEditing = function(field, page)
        page.rateSwitcher.editing = true
    end,

    endPidEditing = function(field, page)
        wf.useApi("mspSetProfile").setRateProfile(field.data.value, function() wf.reloadPage() end, nil)
    end
}

return rateSwitcher