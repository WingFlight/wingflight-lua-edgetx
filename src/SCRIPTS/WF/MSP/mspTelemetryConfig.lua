local function getTelemetryConfig(callback, callbackParam)
    local message = {
        command = 73, -- MSP_TELEMETRY_CONFIG
        processReply = function(self, buf)
            local config = {}
            --wf.print("buf length: "..#buf)
            local offOnTable = { [0] = "OFF", "ON" }
            config.telemetry_inverted = { value = wf.mspHelper.readU8(buf), min = 0, max = 1, table = offOnTable }
            config.telemetry_halfduplex = { value = wf.mspHelper.readU8(buf), min = 0, max = 1, table = offOnTable }
            config.telemetry_sensors = { value = wf.mspHelper.readU32(buf) }
            if wf.apiVersion >= 12.07 then
                config.telemetry_pinswap = { value = wf.mspHelper.readU8(buf), min = 0, max = 1, table = offOnTable }
                config.crsf_telemetry_mode = { value = wf.mspHelper.readU8(buf), min = 0, max = 1, table = { [0] = "NATIVE", "CUSTOM" } }
                config.crsf_telemetry_rate = { value = wf.mspHelper.readU16(buf), min = 0, max = 50000 }
                config.crsf_telemetry_ratio = { value = wf.mspHelper.readU16(buf), min = 0, max = 50000 }
                config.crsf_telemetry_sensors = {}
                for i = 1, 40 do
                    config.crsf_telemetry_sensors[i] = wf.mspHelper.readU8(buf)
                    --wf.print(tostring(config.crsf_telemetry_sensors[i]))
                end
            end

            callback(callbackParam, config)
        end,
        simulatorResponse = { 0, 1, 15, 0, 22, 0, 0, 1, 500, 0, 8, 0, 1, 8, 99, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    }
    wf.mspQueue:add(message)
end

return {
    getTelemetryConfig = getTelemetryConfig
}
