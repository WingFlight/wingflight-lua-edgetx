local lcdShared = ...

local t = {
    text = nil
}

t.update = function()
    if not t.text then return end

    lcd.drawFilledRectangle(wf.radio.SaveBox.x, wf.radio.SaveBox.y, wf.radio.SaveBox.w, wf.radio.SaveBox.h, lcdShared.backgroundFill)
    lcd.drawRectangle(wf.radio.SaveBox.x, wf.radio.SaveBox.y, wf.radio.SaveBox.w, wf.radio.SaveBox.h, SOLID)
    lcd.drawText(wf.radio.SaveBox.x + wf.radio.SaveBox.x_offset, wf.radio.SaveBox.y + wf.radio.SaveBox.h_offset, t.text, DBLSIZE + lcdShared.textOptions)
end

return t