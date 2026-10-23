local addonName, ns = ...

-- The bar
local bar = CreateFrame("Frame", "TalentXTrackerBar", UIParent, "BackdropTemplate")
bar:SetSize(220, 28)
bar:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
bar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
bar:SetBackdropColor(0, 0, 0, 0.6)
bar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

-- Dragging: hold the left mouse button on the bar and move it
bar:SetMovable(true)
bar:SetClampedToScreen(true)
bar:EnableMouse(true)
bar:RegisterForDrag("LeftButton")
bar:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
bar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")
bar.text = text

-- Resizing: drag the small grip in the bottom-right corner
bar:SetResizable(true)
if bar.SetResizeBounds then
    bar:SetResizeBounds(100, 20, 600, 80)
else
    bar:SetMinResize(100, 20)
    bar:SetMaxResize(600, 80)
end

local grip = CreateFrame("Button", nil, bar)
grip:SetSize(14, 14)
grip:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -1, 1)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
grip:SetScript("OnMouseDown", function()
    bar:StartSizing("BOTTOMRIGHT")
end)
grip:SetScript("OnMouseUp", function()
    bar:StopMovingOrSizing()
end)

-- Keep the text sized to the bar
local fontPath = GameFontNormal:GetFont()
text:SetWordWrap(false)

local function ApplySize(self, width, height)
    text:SetWidth(width - 16)
    text:SetFont(fontPath, math.max(8, math.floor(height * 0.5)), "")
end
bar:SetScript("OnSizeChanged", ApplySize)
ApplySize(bar, bar:GetWidth(), bar:GetHeight())

-- Works out the name of the currently selected loadout
local function GetActiveLoadoutName()
    local specID = PlayerUtil.GetCurrentSpecID()
    if not specID then return "No spec" end

    -- Starter Build has no saved loadout of its own
    if C_ClassTalents.GetStarterBuildActive and C_ClassTalents.GetStarterBuildActive() then
        return "Starter Build"
    end

    local ok, configID = pcall(C_ClassTalents.GetLastSelectedSavedConfigID, specID)
    if not ok or not configID then return "Unknown loadout" end
    if configID == -2 then return "Starter Build" end

    local info = C_Traits.GetConfigInfo(configID)
    return (info and info.name) or "Unknown loadout"
end

function ns.UpdateTracker()
    bar.text:SetText(GetActiveLoadoutName())
end

-- Refresh whenever something about talents changes
bar:RegisterEvent("PLAYER_ENTERING_WORLD")
bar:RegisterEvent("TRAIT_CONFIG_UPDATED")
bar:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
bar:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
bar:SetScript("OnEvent", function()
    C_Timer.After(0.3, ns.UpdateTracker)
end)