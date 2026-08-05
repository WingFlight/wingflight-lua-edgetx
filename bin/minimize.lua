print("Minimizing script memory usage...")

-- Step 1:
-- - Remove 'id = "xxx"' entries from fields table in the page files.
-- - Remove 'simulatorResponse = {...}' entries in MSP files.
-- - Remove double spaces in ui.lua to make it compile on some b&w radios.

local genericReplacements = {
    {
        -- Replace wf.call with pcall. Comment out for debugging minimized scripts.
        files = { "/SCRIPTS/WF/", "/WIDGETS/" },
        match = "wf%.call",
        replace = "wf%.call",
        replacement = "pcall"
    },
    {
        -- Remove debug info from release builds.
        files = "/SCRIPTS/WF/COMPILE/compile.lua",
        match = "loadScript%(script, %'cd%'%)",
        replace = "loadScript%(script, %'cd%'%)",
        replacement = "loadScript(script, 'c')"
    },
    {
        -- Replace --[NIR with --[[ to comment out debug code that should not be in a release
        files = { "/SCRIPTS/WF/", "/WIDGETS/" },
        match = "--%[NIR",
        replace = "--%[NIR",
        replacement = "--[["
    },
    {
        -- Remove id = "xxx" from the fields table in page files. This id is not used by the official WingFlight scripts.
        files = "/SCRIPTS/WF/PAGES/",
        match = "^%s-fields%[",
        replace = ",%s-id = \"(.-)\"",
        replacement = ""
    },
    {
        -- Remove 'name = "xxx", ' from the adjfunctions fields table in adj_teller.lua.
        -- Names are only used for debugging and are expensive.
        files = "/SCRIPTS/WF/adj_teller.lua",
        match = "name = \"(.-)\", ",
        replace = "name = \"(.-)\", ",
        replacement = ""
    },
    {
        -- Remove simulatorResponse = {...} from MSP APIs, since they are not used outside the simulator.
        files = "/SCRIPTS/WF/MSP/",
        match = "simulatorResponse = {(.-)}",
        replace = "simulatorResponse = {(.-)},?",
        replacement = ""
    },
    {
        -- large files (>10K)  can't sometimes be compiled on some b&w radios without making it smaller. This is done by removing all double spaces.
        files = { "/SCRIPTS/WF/adj_teller.lua", "/SCRIPTS/WF/wftlm_sensors.lua", "/SCRIPTS/WF/MSP/mspEscAm32.lua" },
        match = "  ",
        replace = "  ",
        replacement = ""
    },
    {
        -- This is also done by replacing ' = ' with '='.
        files = { "/SCRIPTS/WF/adj_teller.lua", "/SCRIPTS/WF/wftlm_sensors.lua", "/SCRIPTS/WF/MSP/mspEscAm32.lua" },
        match = " = ",
        replace = " = ",
        replacement = "="
    },
    {
        -- This is also done by removing comments.
        files = { "/SCRIPTS/WF/adj_teller.lua", "/SCRIPTS/WF/wftlm_sensors.lua", "/SCRIPTS/WF/MSP/mspEscAm32.lua" },
        match = "%-%-.*",
        replace = "%-%-.*",
        replacement = ""
    },
    {
        -- Remove 'wf.lcdNeedsInvalidate*' since it isn't used on EdgeTX/OpenTX
        files = { "/SCRIPTS/WF/" },
        match = "wf%.lcdNeedsInvalidate.*",
        replace = "wf%.lcdNeedsInvalidate.*",
        replacement = ""
    },
}

local function processFile(filename, genericReplacement)
    local input_file = io.open(filename, "r")
    if input_file then
        local temp_file = io.open(filename .. ".tmp", "w") -- Temporary file to store changes

        for line in input_file:lines() do
            local new_line = line
            if string.match(new_line, genericReplacement.match) then
                --print("Found '" .. genericReplacement.match .. "'")
                new_line = string.gsub(new_line, genericReplacement.replace, genericReplacement.replacement)
            end
            temp_file:write(new_line .. "\n")
        end

        input_file:close()
        temp_file:close()

        -- Replace original file with the updated file
        os.remove(filename)
        os.rename(filename .. ".tmp", filename)

        print("Updated " .. filename)
    else
        print("Could not open " .. filename)
    end
end

local function processGenericReplacements()
    local files = assert(loadfile("./SCRIPTS/WF/COMPILE/scripts.lua"))
    local i = 1
    while true do
        local script = files(i)
        i = i + 1
        if script == nil then break end
        for _, genericReplacement in ipairs(genericReplacements) do
            if type(genericReplacement.files) == "table" then
                for _, partialFileName in ipairs(genericReplacement.files) do
                    if string.match(script, partialFileName) then
                        processFile("." .. script, genericReplacement)
                    end
                end
            elseif string.match(script, genericReplacement.files) then
                processFile("." .. script, genericReplacement)
            end
        end
    end
end

processGenericReplacements()

-- Step 2: Replace specific keys with indexes in the specified files.

local mspRcTuningReplacements = {
    files = {
        "SCRIPTS/WF/MSP/mspRcTuning.lua",
        "SCRIPTS/WF/MSP/RATES/ACTUAL.lua",
        "SCRIPTS/WF/MSP/RATES/BETAFL.lua",
        "SCRIPTS/WF/MSP/RATES/KISS.lua",
        "SCRIPTS/WF/MSP/RATES/NONE.lua",
        "SCRIPTS/WF/MSP/RATES/QUICK.lua",
        "SCRIPTS/WF/MSP/RATES/RACEFL.lua",
        "SCRIPTS/WF/MSP/RATES/WINGFL.lua",
        "SCRIPTS/WF/PAGES/rates.lua",
        "SCRIPTS/WF/PAGES/rate_dynamics.lua"
    },

    { ".roll_rcRates", "[0]" },
    { ".roll_rcExpo", "[1]" },
    { ".roll_rates", "[2]" },

    { ".pitch_rcRates", "[3]" },
    { ".pitch_rcExpo", "[4]" },
    { ".pitch_rates", "[5]" },

    { ".yaw_rcRates", "[6]" },
    { ".yaw_rcExpo", "[7]" },
    { ".yaw_rates", "[8]" },

    { ".collective_rcRates", "[9]" },
    { ".collective_rcExpo", "[10]" },
    { ".collective_rates", "[11]" },

    { ".roll_response_time", "[12]" },
    { ".roll_accel_limit", "[13]" },
    { ".pitch_response_time", "[14]" },
    { ".pitch_accel_limit", "[15]" },
    { ".yaw_response_time", "[16]" },
    { ".yaw_accel_limit", "[17]" },
    { ".collective_response_time", "[18]" },
    { ".collective_accel_limit", "[19]" },

    { ".roll_setpoint_boost_gain", "[20]" },
    { ".roll_setpoint_boost_cutoff", "[21]" },
    { ".pitch_setpoint_boost_gain", "[22]" },
    { ".pitch_setpoint_boost_cutoff", "[23]" },
    { ".yaw_setpoint_boost_gain", "[24]" },
    { ".yaw_setpoint_boost_cutoff", "[25]" },
    { ".collective_setpoint_boost_gain", "[26]" },
    { ".collective_setpoint_boost_cutoff", "[27]" },
    { ".yaw_dynamic_ceiling_gain", "[28]" },
    { ".yaw_dynamic_deadband_gain", "[29]" },
    { ".yaw_dynamic_deadband_filter", "[30]" },
}

local mspPidTuningReplacements = {
    files = { "SCRIPTS/WF/MSP/mspPidTuning.lua", "SCRIPTS/WF/PAGES/profile_pids.lua" },

    { ".roll_p", "[0]" },
    { ".roll_i", "[1]" },
    { ".roll_d", "[2]" },
    { ".roll_f", "[3]" },
    { ".pitch_p", "[4]" },
    { ".pitch_i", "[5]" },
    { ".pitch_d", "[6]" },
    { ".pitch_f", "[7]" },
    { ".yaw_p", "[8]" },
    { ".yaw_i", "[9]" },
    { ".yaw_d", "[10]" },
    { ".yaw_f", "[11]" },
    { ".roll_b", "[12]" },
    { ".pitch_b", "[13]" },
    { ".yaw_b", "[14]" },
    { ".roll_o", "[15]" },
    { ".pitch_o", "[16]" },
}

local mspPidProfileReplacements = {
    files = { "SCRIPTS/WF/MSP/mspPidProfile.lua", "SCRIPTS/WF/PAGES/profile_various.lua", "SCRIPTS/WF/PAGES/profile_pidcon.lua" },

    { ".pid_mode", "[0]" },
    { ".iterm_decay_time", "[1]" },
    { ".iterm_decay_limit", "[2]" },
    { ".error_rotation", "[3]" },
    { ".error_limit_roll", "[4]" },
    { ".error_limit_pitch", "[5]" },
    { ".error_limit_yaw", "[6]" },
    { ".gyro_cutoff_roll", "[7]" },
    { ".gyro_cutoff_pitch", "[8]" },
    { ".gyro_cutoff_yaw", "[9]" },
    { ".dterm_cutoff_roll", "[10]" },
    { ".dterm_cutoff_pitch", "[11]" },
    { ".dterm_cutoff_yaw", "[12]" },
    { ".iterm_relax_type", "[13]" },
    { ".iterm_relax_cutoff_roll", "[14]" },
    { ".iterm_relax_cutoff_pitch", "[15]" },
    { ".iterm_relax_cutoff_yaw", "[16]" },
    { ".angle_level_strength", "[17]" },
    { ".angle_level_limit", "[18]" },
    { ".horizon_level_strength", "[19]" },
    { ".trainer_gain", "[20]" },
    { ".trainer_angle_limit", "[21]" },
    { ".atthold_gain", "[22]" },
    { ".atthold_deadband", "[23]" },
    { ".bterm_cutoff_roll", "[24]" },
    { ".bterm_cutoff_pitch", "[25]" },
    { ".bterm_cutoff_yaw", "[26]" },
    { ".fw_tpa_gain", "[27]" },
    { ".fw_tpa_curve", "[28]" },
    { ".master_gain_roll", "[29]" },
    { ".master_gain_pitch", "[30]" },
    { ".master_gain_yaw", "[31]" },
    { ".autohover_gain", "[32]" },
    { ".autohover_max_angle", "[33]" },
    { ".autohover_max_rate", "[34]" },
    { ".cross_axis_relax_strength", "[35]" },
    { ".cross_axis_relax_level", "[36]" },
    { ".cross_axis_relax_cutoff", "[37]" },
    { ".cross_axis_relax_pitch_strength", "[38]" },
    { ".gain_curve_roll", "[39]" },
    { ".gain_curve_pitch", "[40]" },
    { ".gain_curve_yaw", "[41]" },
    { ".atthold_max_rate", "[42]" },
    { ".osc_limiter", "[43]" },
    { ".osc_limiter_min_hz", "[44]" },
    { ".osc_limiter_max_hz", "[45]" },
    { ".osc_limiter_threshold", "[46]" },
    { ".osc_limiter_floor", "[47]" },
    { ".osc_limiter_engage_ms", "[48]" },
}

local mspEscAm32Replacements = {
    files = { "SCRIPTS/WF/MSP/mspEscAm32.lua", "SCRIPTS/WF/PAGES/esc_am32_form.lua" },

    { ".esc_signature", "[0]" },
    { ".esc_command", "[1]" },
    { ".reserved_0", "[2]" },
    { ".eeprom_version", "[3]" },
    { ".reserved_1", "[4]" },
    { ".version_major", "[5]" },
    { ".version_minor", "[6]" },
    { ".max_ramp", "[7]" },
    { ".minimum_duty_cycle", "[8]" },
    { ".disable_stick_calibration", "[9]" },
    { ".absolute_voltage_cutoff", "[10]" },
    { ".current_p", "[11]" },
    { ".current_i", "[12]" },
    { ".current_d", "[13]" },
    { ".active_brake_power", "[14]" },
    { ".reserved_eeprom_3_0", "[15]" },
    { ".reserved_eeprom_3_1", "[16]" },
    { ".reserved_eeprom_3_2", "[17]" },
    { ".reserved_eeprom_3_3", "[18]" },
    { ".timing_advance_encoding", "[19]" },
    { ".motor_direction", "[20]" },
    { ".bidirectional_mode", "[21]" },
    { ".sinusoidal_startup", "[22]" },
    { ".complementary_pwm", "[23]" },
    { ".variable_pwm_frequency", "[24]" },
    { ".stuck_rotor_protection", "[25]" },
    { ".timing_advance", "[26]" },
    { ".pwm_frequency", "[27]" },
    { ".startup_power", "[28]" },
    { ".motor_kv", "[29]" },
    { ".motor_poles", "[30]" },
    { ".brake_on_stop", "[31]" },
    { ".stall_protection", "[32]" },
    { ".beep_volume", "[33]" },
    { ".interval_telemetry", "[34]" },
    { ".servo_low_threshold", "[35]" },
    { ".servo_high_threshold", "[36]" },
    { ".servo_neutral", "[37]" },
    { ".servo_dead_band", "[38]" },
    { ".low_voltage_cutoff", "[39]" },
    { ".low_voltage_threshold", "[40]" },
    { ".rc_car_reversing", "[41]" },
    { ".use_hall_sensors", "[42]" },
    { ".sine_mode_range", "[43]" },
    { ".brake_strength", "[44]" },
    { ".running_brake_level", "[45]" },
    { ".temperature_limit", "[46]" },
    { ".current_limit", "[47]" },
    { ".sine_mode_power", "[48]" },
    { ".esc_protocol", "[49]" },
    { ".auto_advance", "[50]" }
}

local mspEscBlheliSReplacements = {
    files = { "SCRIPTS/WF/MSP/mspEscBlheliS.lua", "SCRIPTS/WF/PAGES/esc_blhelis_form.lua" },

    { ".esc_signature", "[0]" },
    { ".esc_command", "[1]" },
    { ".main_revision", "[2]" },
    { ".sub_revision", "[3]" },
    { ".layout_revision", "[4]" },
    { ".p_gain", "[5]" },
    { ".i_gain", "[6]" },
    { ".governor_mode", "[7]" },
    { ".low_voltage_limit", "[8]" },
    { ".motor_gain", "[9]" },
    { ".motor_idle", "[10]" },
    { ".startup_power", "[11]" },
    { ".pwm_frequency", "[12]" },
    { ".motor_direction", "[13]" },
    { ".input_pwm_polarity", "[14]" },
    { ".mode_raw", "[15]" },
    { ".programming_by_tx", "[16]" },
    { ".rearm_at_start", "[17]" },
    { ".governor_setup_target", "[18]" },
    { ".startup_rpm", "[19]" },
    { ".startup_acceleration", "[20]" },
    { ".volt_comp", "[21]" },
    { ".commutation_timing", "[22]" },
    { ".damping_force", "[23]" },
    { ".governor_range", "[24]" },
    { ".startup_method", "[25]" },
    { ".ppm_min_throttle", "[26]" },
    { ".ppm_max_throttle", "[27]" },
    { ".beep_strength", "[28]" },
    { ".beacon_strength", "[29]" },
    { ".beacon_delay", "[30]" },
    { ".throttle_rate", "[31]" },
    { ".demag_compensation", "[32]" },
    { ".bec_voltage", "[33]" },
    { ".ppm_center_throttle", "[34]" },
    { ".spoolup_time", "[35]" },
    { ".temperature_protection", "[36]" },
    { ".low_rpm_power_protection", "[37]" },
    { ".pwm_input", "[38]" },
    { ".pwm_dither", "[39]" },
    { ".brake_on_stop", "[40]" },
    { ".led_control", "[41]" },
    { ".reserved_29", "[42]" },
    { ".reserved_2a_2b", "[43]" },
    { ".reserved_2c_2f", "[44]" },
    { ".reserved_30_33", "[45]" },
    { ".reserved_34_37", "[46]" },
    { ".reserved_38_3b", "[47]" },
    { ".reserved_3c_3f", "[48]" },
}

local mspEscBluejayReplacements = {
    files = { "SCRIPTS/WF/MSP/mspEscBluejay.lua", "SCRIPTS/WF/PAGES/esc_bluejay_form.lua" },

	{ ".esc_signature", "[0]" },
	{ ".esc_command", "[1]" },
	{ ".main_revision", "[2]" },
	{ ".sub_revision", "[3]" },
	{ ".layout_revision", "[4]" },
	{ ".reserved_03", "[5]" },
	{ ".startup_power_min", "[6]" },
	{ ".startup_beep", "[7]" },
	{ ".dithering", "[8]" },
	{ ".startup_power_max", "[9]" },
	{ ".reserved_08", "[10]" },
	{ ".rpm_power_slope", "[11]" },
	{ ".pwm_frequency", "[12]" },
	{ ".motor_direction", "[13]" },
	{ ".reserved_0c", "[14]" },
	{ ".mode_raw", "[15]" },
	{ ".reserved_0f", "[16]" },
	{ ".breaking_strength", "[17]" },
	{ ".reserved_11_14", "[18]" },
	{ ".commutation_timing", "[19]" },
	{ ".reserved_16_19", "[20]" },
	{ ".reserved_1a", "[21]" },
	{ ".beep_strength", "[22]" },
	{ ".beacon_strength", "[23]" },
	{ ".beacon_delay", "[24]" },
	{ ".reserved_1e", "[25]" },
	{ ".demag_compensation", "[26]" },
	{ ".reserved_20_21", "[27]" },
	{ ".reserved_22", "[28]" },
	{ ".temperature_protection", "[29]" },
	{ ".low_rpm_power_protection", "[30]" },
	{ ".reserved_25_26", "[31]" },
	{ ".brake_on_stop", "[32]" },
	{ ".led_control", "[33]" },
	{ ".power_rating", "[34]" },
	{ ".force_edt_arm", "[35]" },
	{ ".reserved_2b", "[36]" },
	{ ".reserved_2c_2f", "[37]" },
	{ ".reserved_30_33", "[38]" },
	{ ".reserved_34_37", "[39]" },
	{ ".reserved_38_3b", "[40]" },
	{ ".reserved_3c_3f", "[41]" },
}

local wftlm_sensorsReplacements = {
    files = { "SCRIPTS/WF/wftlm_sensors.lua" },

    { "sid=0x", "[0]=0x" },  -- sid becomes [0]
    { ", name=", ", " },     -- name becomes [1]
    { ", unit=", ", " },     -- unit becomes [2]
    { ", prec=", ", " },     -- prec becomes [3]
    { ", dec=", ", " },      -- dec becomes [4]
    {
        "sensor.dec(data, ptr)",
        "(sensor[4])(data, ptr)"
    },
    {
        "setTelemetryValue(sensor.sid, 0, 0, 0, sensor.unit, sensor.prec, sensor.name)",
        "setTelemetryValue(sensor[0], 0, 0, 0, sensor[2], sensor[3], sensor[1])"
    },
    {
        "result[sensor.sid]={ name=sensor.name, sensor.unit, sensor.prec, sensor.dec }",
        "result[sensor[0]]={ sensor[1], sensor[2], sensor[3], sensor[4] }" -- Note: explicitly 1-based so numbers won't change
    },
}

local wftlmReplacements = {
    files = { "SCRIPTS/WF/wftlm.lua" },

    {
        "setTelemetryValue(sid, 0, 0, val, sensor.unit, sensor.prec, sensor.name)",
        "setTelemetryValue(sid, 0, 0, val, sensor[2], sensor[3], sensor[1])"
    },
    {
        "sensor.dec(data, ptr)",
        "(sensor[4])(data, ptr)"
    },
}

function escapeLuaPattern(s)
    return (string.gsub(s, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1"))
end

local function replace(r)
    for _, filename in ipairs(r.files) do
        --print("Opening " .. filename)
        local input_file = io.open(filename, "r")
        if input_file then
            local temp_file = io.open(filename .. ".tmp", "w") -- Temporary file to store changes

            for line in input_file:lines() do
                local new_line = line
                for _, v in ipairs(r) do
                    --new_line = string.gsub(new_line, v[1], v[2])
                    new_line = string.gsub(new_line, escapeLuaPattern(v[1]), v[2])
                end
                temp_file:write(new_line .. "\n")
            end

            input_file:close()
            temp_file:close()

            -- Replace original file with the updated file
            os.remove(filename)
            os.rename(filename .. ".tmp", filename)

            print("Updated " .. filename)
        else
            print("Could not open " .. filename)
        end
    end
end

replace(mspRcTuningReplacements)
replace(mspPidTuningReplacements)
replace(mspPidProfileReplacements)
replace(mspEscAm32Replacements)
replace(mspEscBlheliSReplacements)
replace(mspEscBluejayReplacements)
replace(wftlm_sensorsReplacements)
replace(wftlmReplacements)
