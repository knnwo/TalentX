local addonName, ns = ...

local panel = CreateFrame("Frame")
panel.name = "TalentX"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("TalentX")

-- Checkbox: require Alt+Left-click
local altCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
altCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)

local altLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
altLabel:SetPoint("LEFT", altCheck, "RIGHT", 4, 0)
altLabel:SetText("Require Alt + Left-click to delete a loadout")

altCheck:SetScript("OnClick", function(self)
    TalentXDB.altClick = self:GetChecked() and true or false
end)

-- Checkbox: show tooltip on the X
local tipCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
tipCheck:SetPoint("TOPLEFT", altCheck, "BOTTOMLEFT", 0, -8)

local tipLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
tipLabel:SetPoint("LEFT", tipCheck, "RIGHT", 4, 0)
tipLabel:SetText("Show a tooltip when hovering the X")

tipCheck:SetScript("OnClick", function(self)
    TalentXDB.showTooltip = self:GetChecked() and true or false
end)

-- NEW (slider): how many deleted loadouts to keep
local slider = CreateFrame("Slider", "TalentXBackupSlider", panel, "OptionsSliderTemplate")
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
    local list = TalentXDB.deleted
    if list then
        while #list > value do table.remove(list) end
    end
end)

-- Button: restore the most recently deleted loadout
local restoreBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
restoreBtn:SetSize(240, 26)
restoreBtn:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -6, -32)
restoreBtn:SetText("Restore last deleted loadout")

local function RefreshRestoreButton()
    local list = TalentXDB and TalentXDB.deleted
    if list and #list > 0 then
        restoreBtn:Enable()
        restoreBtn:SetText("Restore: " .. (list[1].name or "last deleted"))
    else
        restoreBtn:Disable()
        restoreBtn:SetText("Nothing to restore")
    end
end

restoreBtn:SetScript("OnClick", function()
    print("TalentX: button clicked, RestoreLast is", ns.RestoreLast and "found" or "MISSING")
    if ns.RestoreLast then ns.RestoreLast() end
    C_Timer.After(1.2, RefreshRestoreButton)
end)

-- Loadout tracker section
local trackerTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
trackerTitle:SetPoint("TOPLEFT", restoreBtn, "BOTTOMLEFT", 0, -28)
trackerTitle:SetText("Loadout tracker bar")

local showCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
showCheck:SetPoint("TOPLEFT", trackerTitle, "BOTTOMLEFT", 0, -8)

local showLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
showLabel:SetPoint("LEFT", showCheck, "RIGHT", 4, 0)
showLabel:SetText("Show the loadout bar")

showCheck:SetScript("OnClick", function(self)
    TalentXDB.trackerShown = self:GetChecked() and true or false
    if ns.ApplyTrackerSettings then ns.ApplyTrackerSettings() end
end)

local lockCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
lockCheck:SetPoint("TOPLEFT", showCheck, "BOTTOMLEFT", 0, -8)

local lockLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
lockLabel:SetPoint("LEFT", lockCheck, "RIGHT", 4, 0)
lockLabel:SetText("Lock position and size (the bar stays clickable)")

lockCheck:SetScript("OnClick", function(self)
    TalentXDB.trackerLocked = self:GetChecked() and true or false
    if ns.ApplyTrackerSettings then ns.ApplyTrackerSettings() end
end)

-- Slider: background opacity of the bar
local opacitySlider = CreateFrame("Slider", "TalentXOpacitySlider", panel, "OptionsSliderTemplate")
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
local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetSize(200, 26)
resetBtn:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", -6, -28)
resetBtn:SetText("Reset bar position and size")
resetBtn:SetScript("OnClick", function()
    if ns.ResetTracker then ns.ResetTracker() end
end)

-- Section: loadout menu text
local menuHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
menuHeader:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 0, -28)
menuHeader:SetText("Loadout menu")

-- Slider: text size
local sizeSlider = CreateFrame("Slider", "TalentXMenuSizeSlider", panel, "OptionsSliderTemplate")
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
    local swatch = CreateFrame("Button", nil, panel)
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
textSwatch:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", -6, -24)

local activeSwatch = CreateColorSwatch("Active loadout color (menu and bar)", "menuActiveColor", { 1, 0.82, 0 })
activeSwatch:SetPoint("TOPLEFT", textSwatch, "BOTTOMLEFT", 0, -10)

-- Button: back to the default text style
local textResetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
textResetBtn:SetSize(170, 24)
textResetBtn:SetPoint("LEFT", menuHeader, "RIGHT", 24, 0)
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
end)



-- Register the page in the game's AddOns settings
local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

function ns.OpenOptions()
    Settings.OpenToCategory(category:GetID())
end