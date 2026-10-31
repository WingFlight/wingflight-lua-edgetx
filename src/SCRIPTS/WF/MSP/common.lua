-- Usage: local mspSendRequest, mspProcessTxQ, mspPollReply, mspClearRxTxBufs = wf.executeScript("MSP/common")
--
-- Compact framing (version 3 in the status byte, telemetry/msp_shared.c in
-- wingflight-firmware): an MSPv2 command with a 3-byte header
--   CMD_LOW CMD_HIGH LEN
-- and, when LEN is 0xFF, LEN_LOW LEN_HIGH after it. No flags byte and no CRC
-- (the telemetry frame has its own). The first S.Port frame then carries two
-- payload bytes instead of a header alone, one frame fewer on most messages.
-- The firmware answers in the framing it was asked in.

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

local MSP_VERSION_BITS = bit32.lshift(3, 5)
local MSP_STARTFLAG = bit32.lshift(1, 4)

local protocolScript = "MSP/" .. wf.executeScript("protocols")
local mspSend, mspPoll, telemetryPush, maxTxBufferSize, maxRxBufferSize = wf.executeScript(protocolScript)

local function mspProcessTxQ()
    if #mspTxBuf == 0 then
        return false
    end
    if not telemetryPush() then
        return true
    end
    local payload = {}
    payload[1] = mspSeq + MSP_VERSION_BITS
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
    mspTxBuf[1] = bit32.band(cmd, 0xFF)
    mspTxBuf[2] = bit32.band(bit32.rshift(cmd, 8), 0xFF)
    if #payload < 255 then
        mspTxBuf[3] = #payload
    else
        mspTxBuf[3] = 0xFF
        mspTxBuf[4] = bit32.band(#payload, 0xFF)
        mspTxBuf[5] = bit32.band(bit32.rshift(#payload, 8), 0xFF)
    end
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
        mspStarted = (mspRxReq == mspLastReq)
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

return mspSendRequest, mspProcessTxQ, mspPollReply, mspClearRxTxBufs
