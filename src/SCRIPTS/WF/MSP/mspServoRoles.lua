-- MSP2_WING_SERVO_ROLES (0x5F3A read / 0x5F3B write): what each servo drives
-- (firmware pg/servo_role.h). Descriptive only: the FC never reads it, it names
-- the servos on the Servos and Mixer Rules pages.
-- One byte per servo: the role in the upper 5 bits, and which servo of that role
-- it is (1-8, stored as 0-7) in the lower 3. The role numbers are fixed by the
-- firmware; 29 and 30 are reserved for roles added later and show as "Unknown".

-- Short names, so they fit next to a value on 128x64 screens.
local roleNames = {
    [0] = "None", "Aileron", "L Aileron", "R Aileron", "Elevator", "L Elev", "R Elev",
    "Rudder", "L V-tail", "R V-tail", "L Elevon", "R Elevon", "Flap", "L Flap", "R Flap",
    "Spoiler", "L Spoiler", "R Spoiler", "Throttle", "TV Pitch", "TV Yaw", "TV Roll",
    "Steering", "Gear", "Brake", "Tow Rel", "Payload", "Smoke", "Choke",
    [31] = "Other"
}

local function roleOf(value)
    return math.floor((value or 0) / 8)
end

-- Text for servo `servo` (0-based): "L Aileron", or "L Aileron 2" when another
-- servo has the same role. Empty for a servo with no role.
local function getLabel(values, servo)
    local value = values[servo]
    local role = roleOf(value)
    if role == 0 then return "" end
    local name = roleNames[role] or "Unknown"
    for i = 0, #values do
        if i ~= servo and roleOf(values[i]) == role then
            return name .. " " .. (value % 8 + 1)
        end
    end
    return name
end

-- Gives `servo` the role and numbers the servos of every role 1, 2, ... in servo
-- order, like the Configurator. Changes `values` in place.
local function setRole(values, servo, role)
    values[servo] = role * 8
    local count = {}
    for i = 0, #values do
        local r = roleOf(values[i])
        if r ~= 0 then
            count[r] = math.min((count[r] or 0) + 1, 8)
            values[i] = r * 8 + count[r] - 1
        elseif values[i] then
            values[i] = 0
        end
    end
end

-- The callback gets the role bytes, 0-based by servo. errorCallback runs on the
-- FC's MSP error reply: firmware without the message.
local function getServoRoles(callback, callbackParam, errorCallback)
    local message = {
        command = 0x5F3A, -- MSP2_WING_SERVO_ROLES
        processReply = function(self, buf)
            local count = #buf > 0 and wf.mspHelper.readU8(buf) or 0
            if #buf < 1 + count then
                if errorCallback then errorCallback(callbackParam) end
                return
            end
            local values = {}
            for i = 0, count - 1 do
                values[i] = wf.mspHelper.readU8(buf)
            end
            callback(callbackParam, values)
        end,
        errorHandler = function(self)
            if errorCallback then errorCallback(callbackParam) end
        end,
        -- Firmware default: L aileron, R aileron, elevator, rudder.
        simulatorResponse = { 4, 16, 24, 32, 56 }
    }
    wf.mspQueue:add(message)
end

local function setServoRole(servoIndex, value)
    local message = {
        command = 0x5F3B, -- MSP2_WING_SET_SERVO_ROLE
        payload = { servoIndex, value },
        simulatorResponse = {}
    }
    wf.mspQueue:add(message)
end

return {
    read = getServoRoles,
    write = setServoRole,
    roleNames = roleNames,
    roleOf = roleOf,
    getLabel = getLabel,
    setRole = setRole
}
