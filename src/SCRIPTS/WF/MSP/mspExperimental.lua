local function getDefaults()
    local defaults = {}
    defaults.length = 0
    for i = 1, 16 do
        defaults[i] = { min = 0, max = 255 }
    end
    return defaults
end

local function getExperimental(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 158, -- MSP_EXPERIMENTAL
        processReply = function(self, buf)
            data.length = #buf
            for i = 1, data.length do
                data[i].value = wf.mspHelper.readU8(buf)
            end
            callback(callbackParam)
        end,
        simulatorResponse = { 21, 10, 70 }
    }
    wf.mspQueue:add(message)
end

local function setExperimental(data)
    local message = {
        command = 159, -- MSP_SET_EXPERIMENTAL
        payload = {}
    }
    for i = 1, data.length do
        wf.mspHelper.writeU8(message.payload, data[i].value)
    end
    wf.mspQueue:add(message)
end

return {
    read = getExperimental,
    write = setExperimental,
    getDefaults = getDefaults
}