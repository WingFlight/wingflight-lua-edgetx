-- Usage: local mspSendRequest, mspProcessTxQ, mspPollReply, mspClearRxTxBufs,
--              setFraming, framingFallbackCount = wf.executeScript("MSP/common")
--
-- Two framings of an MSPv2 command, chosen per link (setFraming()):
--   version 2  FLAGS CMD_LOW CMD_HIGH LEN_LOW LEN_HIGH
--   version 3  CMD_LOW CMD_HIGH LEN, and when LEN is 0xFF, LEN_LOW LEN_HIGH
--              after it (wingflight-firmware telemetry/msp_shared.c)
-- No CRC: the telemetry frame has its own. Version 3 leaves two payload bytes
-- in a 6-byte S.Port start frame that version 2 fills with header alone.
--
-- Every link starts in version 2, so MSP_API_VERSION reads on any firmware.
-- MSP/mspQueue.lua's setFirmwareApi() offers version 3 from the API version
-- that has it. A firmware without it answers a version-3 request with a start
-- frame that has the error bit set and command 0; that drops the link back to
-- version 2 (see mspReceivedReply()). A reply is parsed by the version bits of
-- its own start frame. Kept in step with the Ethos suite's tasks/msp/common.lua.

local mspSeq = 0 -- Sequence number for next MSP packet
local mspRemoteSeq = 0
local mspRxBuf = {}
local mspRxError = false
local mspRxSize = 0
local mspRxReq = 0
local mspStarted = false
local mspLastReq = 0
local mspTxBuf = {}
local mspTxIdx = 1
-- The framing new requests are built in, and the one the request in flight
-- was built in: a fallback mid-request must not relabel its remaining frames.
local mspFraming = 2
local mspTxFraming = 2
-- Times the link fell back from version 3 to 2, ever.
local mspFramingFallbacks = 0

local MSP_STARTFLAG = bit32.lshift(1, 4)

local protocolScript = "MSP/" .. wf.executeScript("protocols")
local mspSend, mspPoll, telemetryPush, maxTxBufferSize, maxRxBufferSize = wf.executeScript(protocolScript)

local function setFraming(version)
    mspFraming = (version == 3) and 3 or 2
end

local function mspProcessTxQ()
    if #mspTxBuf == 0 then
        return false
    end
    if not telemetryPush() then
        return true
    end
    local payload = {}
    payload[1] = mspSeq + bit32.lshift(mspTxFraming, 5)
    mspSeq = bit32.band(mspSeq + 1, 0x0F)
    if mspTxIdx == 1 then
        payload[1] = payload[1] + MSP_STARTFLAG
    end
    local i = 2
    while (i <= maxTxBufferSize) and mspTxIdx <= #mspTxBuf do
        payload[i] = mspTxBuf[mspTxIdx]
        mspTxIdx = mspTxIdx + 1
        i = i + 1
    end
    while i <= maxTxBufferSize do
        payload[i] = 0
        i = i + 1
    end
    mspSend(payload)
    if mspTxIdx > #mspTxBuf then
        mspTxBuf = {}
        mspTxIdx = 1
        return false
    end
    return true
end

local function mspSendRequest(cmd, payload)
    -- busy
    if #mspTxBuf ~= 0 or not cmd then
        return nil
    end
    local cmd1 = bit32.band(cmd, 0xFF)
    local cmd2 = bit32.band(bit32.rshift(cmd, 8), 0xFF)
    local len1 = bit32.band(#payload, 0xFF)
    local len2 = bit32.band(bit32.rshift(#payload, 8), 0xFF)
    if mspFraming == 3 then
        if #payload < 255 then
            mspTxBuf = { cmd1, cmd2, #payload }
        else
            mspTxBuf = { cmd1, cmd2, 0xFF, len1, len2 }
        end
    else
        mspTxBuf = { 0, cmd1, cmd2, len1, len2 }
    end
    mspTxFraming = mspFraming
    for i = 1, #payload do
        mspTxBuf[#mspTxBuf + 1] = bit32.band(payload[i], 0xFF)
    end
    mspLastReq = cmd
    mspTxIdx = 1
    -- a request also drops whatever the previous one left half-assembled
    mspStarted = false
    mspRxBuf = {}
    mspRxSize = 0
    mspRemoteSeq = 0
    return mspProcessTxQ()
end

local function mspReceivedReply(payload)
    local idx = 1
    local status = payload[idx]
    local start = bit32.btest(status, 0x10)
    local seq = bit32.band(status, 0x0F)
    idx = idx + 1
    if start then
        mspRxBuf = {}
        mspRxError = bit32.btest(status, 0x80)
        local version = bit32.band(bit32.rshift(status, 5), 0x03)
        if version == 3 then
            local cmd1 = payload[idx] or 0
            local cmd2 = payload[idx + 1] or 0
            local len = payload[idx + 2] or 0
            idx = idx + 3
            if len == 0xFF then
                len = (payload[idx] or 0) + bit32.lshift(payload[idx + 1] or 0, 8)
                idx = idx + 2
            end
            mspRxReq = cmd1 + bit32.lshift(cmd2, 8)
            mspRxSize = len
        elseif version == 2 then
            idx = idx + 1 -- flags
            mspRxReq = (payload[idx] or 0) + bit32.lshift(payload[idx + 1] or 0, 8)
            mspRxSize = (payload[idx + 2] or 0) + bit32.lshift(payload[idx + 3] or 0, 8)
            idx = idx + 4
        else
            mspStarted = false
            return nil
        end
        -- A firmware without version 3 refuses it: it answers in the request's
        -- version bits, with the error bit, and lays out command 0 as MSPv2,
        -- which reads here as command 0 and length 0. No firmware that has
        -- version 3 sends command 0. Fall back to version 2 for this link and
        -- hand the request back, so the queue resends it at once. Only once:
        -- refusals of the request's other frames find the link on version 2.
        if mspRxError and mspRxReq == 0 and mspTxFraming == 3 and mspFraming == 3 then
            mspFraming = 2
            mspFramingFallbacks = mspFramingFallbacks + 1
            mspTxBuf = {}
            mspTxIdx = 1
            mspStarted = false
            return nil
        end
        mspStarted = (mspRxReq == mspLastReq)
        if not mspStarted then
            -- a late reply to an earlier command: not ours. Taking it as a
            -- complete reply would clear mspLastReq, and the real reply's
            -- start frame would then no longer match.
            return nil
        end
    elseif not mspStarted then
        return nil
    elseif bit32.band(mspRemoteSeq + 1, 0x0F) ~= seq then
        mspStarted = false
        return nil
    end
    while (idx <= maxRxBufferSize) and (#mspRxBuf < mspRxSize) do
        mspRxBuf[#mspRxBuf + 1] = payload[idx]
        idx = idx + 1
    end
    if #mspRxBuf < mspRxSize then
        -- continues in the next frame
        mspRemoteSeq = seq
        return false
    end
    mspStarted = false
    return true
end

local function mspPollReply()
    local startTime = wf.clock()
    while wf.clock() - startTime < 0.005 do
        local mspData = mspPoll()
        if mspData == nil then
            return
        end
        if mspReceivedReply(mspData) then
            mspLastReq = 0
            return mspRxReq, mspRxBuf, mspRxError
        end
    end
end

local function mspClearRxTxBufs()
    mspTxBuf = {}
    mspTxIdx = 1
    mspStarted = false
    while mspPoll() do end
end

local function framingFallbackCount()
    return mspFramingFallbacks
end

return mspSendRequest, mspProcessTxQ, mspPollReply, mspClearRxTxBufs, setFraming, framingFallbackCount
