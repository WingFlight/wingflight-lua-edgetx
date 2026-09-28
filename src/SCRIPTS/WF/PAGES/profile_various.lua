local template = wf.executeScript(wf.radio.template)
local margin = template.margin
local indent = template.indent
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local sp = template.listSpacing.field
template = nil
local yMinLim = wf.radio.yMinLimit
local x = margin
local y = yMinLim - lineSpacing
local function incY(val) y = y + val return y end
local labels = {}
local fields = {}
local profileSwitcher = wf.executeScript("PAGES/helpers/profileSwitcher.lua")
local pidProfile = wf.useApi("mspPidProfile").getDefaults()
collectgarbage()

fields[#fields + 1] = { t = "Current PID profile",     x = x,          y = incY(lineSpacing), sp = x + sp * 1.17, data = { value = nil, min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } }, preEdit = profileSwitcher.startPidEditing, postEdit = profileSwitcher.endPidEditing }

-- Build once after the reply so old firmware only shows supported fields.
local function buildProfileFields()
    for i = #fields, 2, -1 do fields[i] = nil end
    for i = #labels, 1, -1 do labels[i] = nil end
    y = fields[1].y
    incY(lineSpacing * 0.25)
    labels[#labels + 1] = { t = "Trainer",            x = x,          y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Gain",                    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.trainer_gain,                   id = "profilesAcroTrainerGain" }
    if pidProfile.has_axis_limits then
        fields[#fields + 1] = { t = "Bank limit", x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.trainer_roll_limit }
        fields[#fields + 1] = { t = "Pitch limit", x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.trainer_pitch_limit }
    else
        fields[#fields + 1] = { t = "Maximum angle",           x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.trainer_angle_limit,            id = "profilesAcroTrainerLimit" }
    end
    labels[#labels + 1] = { t = "Angle Mode",              x = x,          y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Leveling gain",           x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.angle_level_strength,           id = "profilesAngleModeGain" }
    if pidProfile.has_axis_limits then
        fields[#fields + 1] = { t = "Bank limit", x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.angle_roll_limit }
        fields[#fields + 1] = { t = "Pitch limit", x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.angle_pitch_limit }
    else
        fields[#fields + 1] = { t = "Maximum angle",           x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.angle_level_limit,              id = "profilesAngleModeLimit" }
    end
    labels[#labels + 1] = { t = "Horizon Mode",            x = x,          y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Leveling gain",           x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.horizon_level_strength,         id = "profilesHorizonModeGain" }

    incY(lineSpacing * 0.25)
    labels[#labels + 1] = { t = "Throttle",                x = x,          y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Gain",                    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_tpa_gain }
    if pidProfile.has_fw_spa then
        -- GPS speed attenuation: needs a GPS fix and a Speed curve below
        labels[#labels + 1] = { t = "GPS Speed",           x = x,          y = incY(lineSpacing) }
        fields[#fields + 1] = { t = "Gain",                x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_spa_gain }
    end

    incY(lineSpacing * 0.25)
    labels[#labels + 1] = { t = "Flight Feel",             x = x,          y = incY(lineSpacing) }
    labels[#labels + 1] = { t = "Master Gain",             x = x + indent, y = incY(lineSpacing), bold = false }
    fields[#fields + 1] = { t = "Roll",                    x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.master_gain_roll }
    fields[#fields + 1] = { t = "Pitch",                   x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.master_gain_pitch }
    fields[#fields + 1] = { t = "Yaw",                     x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.master_gain_yaw }
    labels[#labels + 1] = { t = "I-term Decay",            x = x + indent, y = incY(lineSpacing), bold = false }
    fields[#fields + 1] = { t = "Roll",                    x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_decay_time_roll }
    fields[#fields + 1] = { t = "Pitch",                   x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_decay_time_pitch }
    fields[#fields + 1] = { t = "Yaw",                     x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_decay_time_yaw }
    labels[#labels + 1] = { t = "I-term Relax",            x = x + indent, y = incY(lineSpacing), bold = false }
    fields[#fields + 1] = { t = "Roll",                    x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.bounceback_roll }
    fields[#fields + 1] = { t = "Pitch",                   x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.bounceback_pitch }
    fields[#fields + 1] = { t = "Yaw",                     x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.bounceback_yaw }

    -- Gain curves (advanced shaping), kept apart from Flight Feel
    incY(lineSpacing * 0.25)
    labels[#labels + 1] = { t = "Gain Curves",             x = x,          y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Roll",                    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.gain_curve_roll }
    fields[#fields + 1] = { t = "Pitch",                   x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.gain_curve_pitch }
    fields[#fields + 1] = { t = "Yaw",                     x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.gain_curve_yaw }
    fields[#fields + 1] = { t = "Throttle",                x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_tpa_curve }
    if pidProfile.has_fw_spa then
        fields[#fields + 1] = { t = "Speed",               x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_spa_curve }
        fields[#fields + 1] = { t = "Speed range",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_spa_speed_max }
    end

    incY(lineSpacing * 0.25)
    labels[#labels + 1] = { t = "Cross-Axis Relax",        x = x,          y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Roll strength",           x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.cross_axis_relax_strength }
    fields[#fields + 1] = { t = "Pitch strength",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.cross_axis_relax_pitch_strength }
    fields[#fields + 1] = { t = "Level",                   x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.cross_axis_relax_level }
    fields[#fields + 1] = { t = "Cutoff",                  x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.cross_axis_relax_cutoff }

end

local function receivedPidProfile(page, _)
    buildProfileFields()
    wf.onPageReady(page)
end

return {
    read = function(self)
        self.profileSwitcher.getStatus(self)
        wf.useApi("mspPidProfile").read(receivedPidProfile, self, pidProfile)
    end,
    write = function(self)
        if pidProfile.trainer_gain.value then
            wf.useApi("mspPidProfile").write(pidProfile)
            wf.settingsSaved(true, false)
        end
    end,
    title       = "Profile - Various",
    labels      = labels,
    fields      = fields,
    profileSwitcher = profileSwitcher,

    timer = function(self)
        self.profileSwitcher.checkStatus(self)
    end,
}
