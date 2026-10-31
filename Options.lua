local addonName, ns = ...

local panel = CreateFrame("Frame")
panel.name = "TalentX"

-- All three buttons on this page share one size
local BUTTON_W, BUTTON_H = 240, 26

-- The page scrolls, so it can never overflow the settings window.
-- Everything below is created inside "content", which sits inside the scroll frame.
local scroll
do
    local ok, frame = pcall(CreateFrame, "ScrollFrame", "TalentXOptionsScroll", panel, "UIPanelScrollFrameTemplate")
    if ok and frame then
        scroll = frame
    else
        -- The game's scroll template is missing: use a plain scroll frame that scrolls with the mouse wheel
        scroll = CreateFrame("ScrollFrame", nil, panel)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local target = self:GetVerticalScroll() - delta * 30
            self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), target)))
        end)
    end
end
scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -4)
scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 4)

local content = CreateFrame("Frame", nil, scroll)
content:SetSize(560, 730)
scroll:SetScrollChild(content)
scroll:HookScript("OnSizeChanged", function(self, width)
    content:SetWidth(math.max(1, width))
end)

local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("TalentX")

-- Checkbox: require Alt+Left-click
local altCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
altCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)

local altLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
altLabel:SetPoint("LEFT", altCheck, "RIGHT", 4, 0)
altLabel:SetText("Require Alt + Left-click to delete a loadout")

altCheck:SetScript("OnClick", function(self)
    TalentXDB.altClick = self:GetChecked() and true or false
end)

-- Checkbox: show tooltip on the X
local tipCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
tipCheck:SetPoint("TOPLEFT", altCheck, "BOTTOMLEFT", 0, -8)

local tipLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
tipLabel:SetPoint("LEFT", tipCheck, "RIGHT", 4, 0)
tipLabel:SetText("Show a tooltip when hovering the X")

tipCheck:SetScript("OnClick", function(self)
    TalentXDB.showTooltip = self:GetChecked() and true or false
end)

-- Slider: how many deleted loadouts to keep
local slider = CreateFrame("Slider", "TalentXBackupSlider", content, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", tipCheck, "BOTTOMLEFT", 6, -32)
slider:SetWidth(220)
slider:SetMinMaxValues(1, 10)
slider:SetValueStep(1)
slider:SetObeyStepOnDrag(true)

local sliderText = slider.Text or _G["TalentXBackupSliderText"]
local sliderLow = slider.Low or _G["TalentXBackupSliderLow"]
local sliderHigh = slider.High or _G["TalentXBackupSliderHigh"]
sliderLow:SetText("1")
sliderHigh:SetText("10")

slider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    sliderText:SetText("Deleted loadouts kept per session: " .. value)
    if not TalentXDB then return end
    TalentXDB.maxUndo = value
    if ns.TrimBackups then ns.TrimBackups(value) end
end)

-- Button: restore the most recently deleted loadout
local restoreBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
restoreBtn:SetSize(BUTTON_W, BUTTON_H)
restoreBtn:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -6, -32)
restoreBtn:SetText("Restore last deleted loadout")

local function RefreshRestoreButton()
    local entry = ns.GetRestorable and ns.GetRestorable()
    if entry then
        restoreBtn:Enable()
        restoreBtn:SetText("Restore: " .. (entry.name or "last deleted"))
    else
        restoreBtn:Disable()
        restoreBtn:SetText("Nothing to restore")
    end
end

restoreBtn:SetScript("OnClick", function()
    if ns.RestoreLast then ns.RestoreLast() end
    C_Timer.After(1.2, RefreshRestoreButton)
end)

-- Loadout tracker section
local trackerTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
trackerTitle:SetPoint("TOPLEFT", restoreBtn, "BOTTOMLEFT", 0, -28)
trackerTitle:SetText("Loadout tracker bar")

local showCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
showCheck:SetPoint("TOPLEFT", trackerTitle, "BOTTOMLEFT", 0, -8)

local showLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
showLabel:SetPoint("LEFT", showCheck, "RIGHT", 4, 0)
showLabel:SetText("Show the loadout bar")

showCheck:SetScript("OnClick", function(self)
    TalentXDB.trackerShown = self:GetChecked() and true or false
    if ns.ApplyTrackerSettings then ns.ApplyTrackerSettings() end
end)

local lockCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
lockCheck:SetPoint("TOPLEFT", showCheck, "BOTTOMLEFT", 0, -8)

local lockLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
lockLabel:SetPoint("LEFT", lockCheck, "RIGHT", 4, 0)
lockLabel:SetText("Lock position and size (the bar stays clickable)")

lockCheck:SetScript("OnClick", function(self)
    TalentXDB.trackerLocked = self:GetChecked() and true or false
    if ns.ApplyTrackerSettings then ns.ApplyTrackerSettings() end
end)

-- Slider: background opacity of the bar
local opacitySlider = CreateFrame("Slider", "TalentXOpacitySlider", content, "OptionsSliderTemplate")
opacitySlider:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 6, -32)
opacitySlider:SetWidth(220)
opacitySlider:SetMinMaxValues(0, 100)
opacitySlider:SetValueStep(5)
opacitySlider:SetObeyStepOnDrag(true)

local opacityText = opacitySlider.Text or _G["TalentXOpacitySliderText"]
local opacityLow = opacitySlider.Low or _G["TalentXOpacitySliderLow"]
local opacityHigh = opacitySlider.High or _G["TalentXOpacitySliderHigh"]
opacityLow:SetText("0%")
opacityHigh:SetText("100%")

opacitySlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    opacityText:SetText("Bar background opacity: " .. value .. "%")
    if not TalentXDB then return end
    TalentXDB.trackerOpacity = value / 100
    if ns.ApplyTrackerSettings then ns.ApplyTrackerSettings() end
end)

-- Button: reset the bar's position and size
local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
resetBtn:SetSize(BUTTON_W, BUTTON_H)
resetBtn:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", -6, -28)
resetBtn:SetText("Reset bar position and size")
resetBtn:SetScript("OnClick", function()
    if ns.ResetTracker then ns.ResetTracker() end
end)

-- Section: loadout menu text
local menuHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
menuHeader:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 0, -28)
menuHeader:SetText("Loadout menu")

-- Slider: text size
local sizeSlider = CreateFrame("Slider", "TalentXMenuSizeSlider", content, "OptionsSliderTemplate")
sizeSlider:SetPoint("TOPLEFT", menuHeader, "BOTTOMLEFT", 6, -24)
sizeSlider:SetWidth(220)
sizeSlider:SetMinMaxValues(10, 20)
sizeSlider:SetValueStep(1)
sizeSlider:SetObeyStepOnDrag(true)

local sizeText = sizeSlider.Text or _G["TalentXMenuSizeSliderText"]
local sizeLow = sizeSlider.Low or _G["TalentXMenuSizeSliderLow"]
local sizeHigh = sizeSlider.High or _G["TalentXMenuSizeSliderHigh"]
sizeLow:SetText("10")
sizeHigh:SetText("20")

sizeSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    sizeText:SetText("Menu text size: " .. value)
    if not TalentXDB then return end
    TalentXDB.menuFontSize = value
end)

-- A small colour swatch with a label; clicking it opens the game's colour picker
local function CreateColorSwatch(label, dbKey, default)
    local swatch = CreateFrame("Button", nil, content)
    swatch:SetSize(24, 24)

    local border = swatch:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0.4, 0.4, 0.4, 1)

    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)

    local caption = swatch:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    caption:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
    caption:SetText(label)

    local function GetColor()
        local c = (TalentXDB and TalentXDB[dbKey]) or default
        return c[1], c[2], c[3]
    end

    function swatch:Refresh()
        fill:SetColorTexture(GetColor())
        if ns.UpdateTracker then ns.UpdateTracker() end -- the bar follows the colours live
    end

    swatch:SetScript("OnClick", function(self)
        local r, g, b = GetColor()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            hasOpacity = false,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                if TalentXDB then TalentXDB[dbKey] = { nr, ng, nb } end
                self:Refresh()
            end,
            cancelFunc = function()
                if TalentXDB then TalentXDB[dbKey] = { r, g, b } end
                self:Refresh()
            end,
        })
    end)

    return swatch
end

-- These defaults must match the ones in Menu.lua
local textSwatch = CreateColorSwatch("Loadout text color", "menuTextColor", { 0.92, 0.92, 0.92 })
textSwatch:SetPoint("TOPLEFT", sizeSlider, "TOPRIGHT", 40, 4)

local activeSwatch = CreateColorSwatch("Active loadout color (menu and bar)", "menuActiveColor", { 1, 0.82, 0 })
activeSwatch:SetPoint("TOPLEFT", textSwatch, "BOTTOMLEFT", 0, -10)

-- Button: back to the default text style
local textResetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
textResetBtn:SetSize(BUTTON_W, BUTTON_H)
textResetBtn:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", -6, -20)
textResetBtn:SetText("Reset menu text style")
textResetBtn:SetScript("OnClick", function()
    if TalentXDB then
        TalentXDB.menuFontSize = nil
        TalentXDB.menuTextColor = nil
        TalentXDB.menuActiveColor = nil
    end
    sizeSlider:SetValue(13)
    textSwatch:Refresh()
    activeSwatch:Refresh()
end)

-- Section: instance reminder
local remindHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
remindHeader:SetPoint("TOPLEFT", textResetBtn, "BOTTOMLEFT", 0, -28)
remindHeader:SetText("Instance reminder")

local remindCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
remindCheck:SetPoint("TOPLEFT", remindHeader, "BOTTOMLEFT", 0, -8)

local remindLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
remindLabel:SetPoint("LEFT", remindCheck, "RIGHT", 4, 0)
remindLabel:SetText("Remind me to check my build when I enter a dungeon or raid")

remindCheck:SetScript("OnClick", function(self)
    TalentXDB.remindOnEnter = self:GetChecked() and true or false
end)

-- Button: show the reminder now, so you can see what it looks like
local remindBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
remindBtn:SetSize(BUTTON_W, BUTTON_H)
remindBtn:SetPoint("TOPLEFT", remindCheck, "BOTTOMLEFT", 0, -8)
remindBtn:SetText("Preview the reminder")
remindBtn:SetScript("OnClick", function()
    if ns.ShowBuildReminder then ns.ShowBuildReminder("Preview") end
end)

-- Saved settings aren't loaded when this file runs, so read them each time the page opens
panel:SetScript("OnShow", function()
    altCheck:SetChecked(TalentXDB and TalentXDB.altClick)
    tipCheck:SetChecked(TalentXDB and TalentXDB.showTooltip ~= false)
    slider:SetValue((TalentXDB and TalentXDB.maxUndo) or 5)
    RefreshRestoreButton()
    showCheck:SetChecked(not (TalentXDB and TalentXDB.trackerShown == false))
    lockCheck:SetChecked(TalentXDB and TalentXDB.trackerLocked == true)
    opacitySlider:SetValue(((TalentXDB and TalentXDB.trackerOpacity) or 0.6) * 100)
    sizeSlider:SetValue((TalentXDB and TalentXDB.menuFontSize) or 13)
    textSwatch:Refresh()
    activeSwatch:Refresh()
    remindCheck:SetChecked(not (TalentXDB and TalentXDB.remindOnEnter == false))
end)

-- Register the page in the game's AddOns settings
local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

function ns.OpenOptions()
    Settings.OpenToCategory(category:GetID())
end