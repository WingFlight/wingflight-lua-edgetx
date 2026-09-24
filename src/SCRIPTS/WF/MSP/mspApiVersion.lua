local REQUIRED_API_MAJOR = 22
local REQUIRED_API_MINOR = 4

local function makeVersion(major, minor)
    return major + minor / 100 + 0.00001
end

local function versionString(major, minor)
    return string.format("%d.%02d", major, minor)
end

local function requiredVersionString()
    return versionString(REQUIRED_API_MAJOR, REQUIRED_API_MINOR)
end

local function isSupported(major, minor)
    return major == REQUIRED_API_MAJOR and minor == REQUIRED_API_MINOR
end

local function getApiVersion(callback, callbackParam)
    local message = {
        command = 1, -- MSP_API_VERSION
        processReply = function(self, buf)
            if #buf >= 3 then
                local major = buf[2]
                local minor = buf[3]
                callback(callbackParam, makeVersion(major, minor), major, minor)
            end
        end,
        simulatorResponse = { 0, 22, 4 }
    }
    wf.mspQueue:add(message)
end

return {
    getApiVersion = getApiVersion,
    isSupported = isSupported,
    requiredVersionString = requiredVersionString,
    versionString = versionString,
}
