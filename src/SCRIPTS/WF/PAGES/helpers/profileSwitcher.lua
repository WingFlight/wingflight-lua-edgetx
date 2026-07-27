local profileSwitcher = {
    mspStatus = wf.executeScript("MSP/mspStatus"),
    editing = false,
    profileAdjustmentTS = nil,

    getStatus = function(page)
        local self = page.profileSwitcher
        self.mspStatus.getStatus(self.onProcessedMspStatus, page)
    end,

    checkStatus = function(page)
        local self = page.profileSwitcher
        if self.profileAdjustmentTS and wf.clock() - self.profileAdjustmentTS > 0.5 then
            wf.reloadPage()
        elseif wf.mspQueue:isProcessed() and not self.editing then
            self.mspStatus.getStatus(self.onProcessedMspStatus, page)
        end
    end,

    onProcessedMspStatus = function(page, status)
        local self = page.profileSwitcher
        local currentField = page.fields[1]
        if currentField.data.value ~= status.profile and not self.editing then
            if currentField.data.value then
                self.profileAdjustmentTS = wf.clock()
            end
            currentField.data.value = status.profile
            wf.lcdNeedsInvalidate = true
        end

        page.isReady = true
    end,

    startPidEditing = function(field, page)
        page.profileSwitcher.editing = true
    end,

    endPidEditing = function(field, page)
        wf.useApi("mspSetProfile").setPidProfile(field.data.value, function() wf.reloadPage() end, nil)
    end
}

return profileSwitcher