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
    sliderText:SetText("Deleted loadouts kept for undo: " .. value)
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

-- Saved settings aren't loaded when this file runs, so read them each time the page opens
panel:SetScript("OnShow", function()
    altCheck:SetChecked(TalentXDB and TalentXDB.altClick)
    tipCheck:SetChecked(TalentXDB and TalentXDB.showTooltip ~= false)
    slider:SetValue((TalentXDB and TalentXDB.maxUndo) or 5)
    RefreshRestoreButton()
end)

-- Register the page in the game's AddOns settings
local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

function ns.OpenOptions()
    Settings.OpenToCategory(category:GetID())
end