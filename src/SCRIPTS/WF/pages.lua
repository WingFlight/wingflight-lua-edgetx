local PageFiles = {}
local settings = wf.loadSettings()

local function addPage(key, title, script, showIfNotSet)
    if settings[key] == 1 or (showIfNotSet and not settings[key]) then
        PageFiles[#PageFiles + 1] = { title = title, script = script }
    end
end

addPage("showStatus", "Status", "status", true)
addPage("showRates", "Rates", "rates", true)
addPage("showRateDynamics", "Rate Dynamics", "rate_dynamics", true)
addPage("showPidGains", "PID Gains", "profile_pids", true)
addPage("showPidController", "PID Controller", "profile_pidcon", true)
addPage("showProfileVarious", "Profile - Various", "profile_various", true)
if wf.apiVersion >= 12.09 then
    addPage("showBattery", "Battery", "battery", true)
    addPage("showSmartFuel", "Smart Fuel", "smartfuel", true)
end
addPage("showServos", "Servos", "servos", true)
addPage("showMixer", "Mixer", "mixer", true)
addPage("showMixerInputs", "Mixer Inputs", "mixer_inputs", false)
addPage("showMixerRules", "Mixer Rules", "mixer_rules", false)
addPage("showGyroFilters", "Gyro Filters", "filters", true)
addPage("showAccelerometerTrim", "Accelerometer Trim", "accelerometer", true)
addPage("showEscSensor", "ESC Sensor", "esc_sensor", true)

if wf.apiVersion >= 12.07 then
    addPage("showModelOnTx", "Model", "model", true)
    addPage("showExperimental", "Experimental (!)", "experimental", false)
    if wf.apiVersion >= 12.09 then
        addPage("showAm32", "ESC - AM32", "esc_am32", false)
        addPage("showBlheliS", "ESC - BLHeli_S", "esc_blhelis", false)
        addPage("showBluejay", "ESC - Bluejay", "esc_bluejay", false)
    end
    addPage("showFlyRotor", "ESC - FLYROTOR", "esc_flyrotor", false)
    addPage("showPlatinumV5", "ESC - HW Platinum V5", "esc_hwpl5", false)
    addPage("showTribunus", "ESC - Scorpion Tribunus", "esc_scorp", false)
    if wf.apiVersion >= 12.08 then
        addPage("showXdfly", "ESC - XDFly/OMP/ZTW", "esc_xdfly", false)
    end
    addPage("showYge", "ESC - YGE", "esc_yge", false)

    PageFiles[#PageFiles + 1] = { title = "Settings", script = "settings" }
end

return PageFiles
