local function getFeatureConfig(callback, callbackParam)
    local message = {
        command = 36, -- MSP_FEATURE_CONFIG
        processReply = function(self, buf)
            local config = {}
            --wf.print("buf length: "..#buf)
            config.bitfield = wf.mspHelper.readU32(buf)
            callback(callbackParam, config)
        end,
        simulatorResponse = { 8, 4, 0, 124 }
    }
    wf.mspQueue:add(message)
end

return {
    getFeatureConfig = getFeatureConfig,
    telemetryIsEnabled = function(bitfield)
        return bit32.btest(bitfield, 10)
    end
}
