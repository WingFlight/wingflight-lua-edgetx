local function getStatus(callback, callbackParam)
    local message = {
        command = 101, -- MSP_STATUS
        processReply = function(self, buf)
            local status = {}
            --status.pidCycleTime = wf.mspHelper.readU16(buf)
            --status.gyroCycleTime = wf.mspHelper.readU16(buf)
            buf.offset = 7
            status.flightModeFlags = wf.mspHelper.readU32(buf)
            buf.offset = 12
            status.realTimeLoad = wf.mspHelper.readU16(buf)
            --wf.print("Real-time load: "..tostring(status.realTimeLoad))
            status.cpuLoad = wf.mspHelper.readU16(buf)
            --wf.print("CPU load: "..tostring(status.cpuLoad))
            buf.offset = 18
            status.armingDisableFlags = wf.mspHelper.readU32(buf)
            --wf.print("Arming disable flags: "..tostring(status.armingDisableFlags))
            buf.offset = 24
            status.profile = wf.mspHelper.readU8(buf)
            --wf.print("Profile: "..tostring(status.profile))
            --status.numProfiles = wf.mspHelper.readU8(buf)
            buf.offset = 26
            status.rateProfile = wf.mspHelper.readU8(buf)
            --status.numRateProfiles = wf.mspHelper.readU8(buf)
            buf.offset = 28
            status.motorCount = wf.mspHelper.readU8(buf)
            --wf.print("Number of motors: "..tostring(status.motorCount))
            --status.servoCount = wf.mspHelper.readU8(buf)
            --wf.print("Number of servos: "..tostring(status.servoCount))
            callback(callbackParam, status)
        end,
        simulatorResponse = { 240, 1, 124, 0, 35, 0, 0, 0, 0, 0, 0, 224, 1, 10, 1, 0, 26, 0, 0, 0, 0, 0, 2, 0, 6, 0, 6, 2, 4, 1 }
    }

    wf.mspQueue:add(message)
end

return {
    getStatus = getStatus
}