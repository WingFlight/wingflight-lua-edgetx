local escParameters = nil
local escCount = 0
local selectedEsc = 0

local function clearForm(page)
    page.labels = {}
    page.fields = {}
    collectgarbage()
end

local receivedEscParameters -- forward declaration needed

local endEscEditing = function(field, page)
    selectedEsc = field.data.value
    clearForm(page)
    wf.useApi("mspEsc4wif").selectEsc(selectedEsc)
    wf.useApi("mspEscBluejay").read(receivedEscParameters, page)
end

receivedEscParameters = function(page, data)
    escParameters = data
    clearForm(page)
    page.labels, page.fields = wf.executeScript("PAGES/esc_bluejay_form", escParameters, escCount, selectedEsc, endEscEditing)
    page.readOnly = false
    wf.onPageReady(page)
end

local function onProcessedMspStatus(page, status)
    escCount = status.motorCount
end

local page = {
    read = function(self)
        if not self.isReady then wf.onPageReady(self) end
        wf.useApi("mspEsc4wif").selectEsc(selectedEsc, 2)
        wf.useApi("mspStatus").getStatus(onProcessedMspStatus, self)
        wf.useApi("mspEscBluejay").read(receivedEscParameters, self)
    end,
    write = function(self)
        clearForm(self)
        wf.useApi("mspEscBluejay").write(escParameters)
        escParameters = nil
        wf.useApi("mspEscBluejay").read(receivedEscParameters, self)
    end,
    unload = function(self)
        wf.useApi("mspEsc4wif").clearEscSelection()
    end,
    title       = "Bluejay",
    readOnly    = true
}

page.labels, page.fields = wf.executeScript("PAGES/esc_bluejay_form", nil)

return page