local addonName, ns = ...

local SHOW_SECONDS = 5 -- how long the reminder stays before it starts to fade
local FADE_SECONDS = 2

-- The banner
local banner = CreateFrame("Frame", "TalentXReminder", UIParent, "BackdropTemplate")
banner:SetSize(340, 74)
banner:SetPoint("TOP", UIParent, "TOP", 0, -160)
banner:SetFrameStrata("DIALOG")
banner:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
banner:SetBackdropColor(0.07, 0.07, 0.09, 0.95)
banner:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
banner:EnableMouse(true)
banner:Hide()

-- A thin bar on the left in the loadout's colour
local accent = banner:CreateTexture(nil, "ARTWORK")
accent:SetPoint("TOPLEFT")
accent:SetPoint("BOTTOMLEFT")
accent:SetWidth(4)

local header = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
header:SetPoint("TOP", 0, -9)
header:SetText("CHECK YOUR TALENTS")
header:SetTextColor(0.6, 0.6, 0.65)

local nameText = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
nameText:SetPoint("TOP", header, "BOTTOM", 0, -6)
nameText:SetWidth(310)
nameText:SetWordWrap(false)

local placeText = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
placeText:SetPoint("TOP", nameText, "BOTTOM", 0, -6)
placeText:SetTextColor(0.6, 0.6, 0.65)

-- Fading out
local fade = banner:CreateAnimationGroup()
local fadeAlpha = fade:CreateAnimation("Alpha")
fadeAlpha:SetFromAlpha(1)
fadeAlpha:SetToAlpha(0)
fadeAlpha:SetDuration(FADE_SECONDS)
fade:SetToFinalAlpha(true)
fade:SetScript("OnFinished", function()
    banner:Hide()
    banner:SetAlpha(1)
end)

local showToken = 0 -- changes every time the banner is shown or dismissed, to cancel old timers

-- Click the banner to close it
banner:SetScript("OnMouseUp", function()
    showToken = showToken + 1
    fade:Stop()
    banner:Hide()
    banner:SetAlpha(1)
end)

-- Same colours as the loadout bar
local function StateColor(state)
    if state == "none" then return 1, 0.1, 0.1 end
    if state == "starter" then return 0, 0.77, 1 end
    local c = TalentXDB and TalentXDB.menuActiveColor
    if c then return c[1], c[2], c[3] end
    return 1, 0.82, 0
end

-- Shows the banner with the current loadout. "placeLabel" is the small line underneath.
function ns.ShowBuildReminder(placeLabel)
    if not ns.GetActiveLoadoutState then return end
    local loadout, state = ns.GetActiveLoadoutState()
    local r, g, b = StateColor(state)

    nameText:SetText(loadout)
    nameText:SetTextColor(r, g, b)
    accent:SetColorTexture(r, g, b, 1)
    placeText:SetText(placeLabel or "")

    fade:Stop()
    banner:SetAlpha(1)
    banner:Show()

    showToken = showToken + 1
    local token = showToken
    C_Timer.After(SHOW_SECONDS, function()
        if token == showToken and banner:IsShown() then
            fade:Play()
        end
    end)
end

-- Entering a dungeon or raid
local handledThisInstance = false -- true while we are inside an instance we already dealt with

local function OnEnteringWorld(isReloadingUi)
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid") then
        handledThisInstance = false
        return
    end

    -- Zoning inside the same instance (or a /reload there) must not remind again
    if handledThisInstance then return end
    handledThisInstance = true
    if isReloadingUi then return end
    if TalentXDB and TalentXDB.remindOnEnter == false then return end

    local name, _, _, difficultyName = GetInstanceInfo()
    local place = name or ""
    if difficultyName and difficultyName ~= "" then
        place = place .. "  -  " .. difficultyName
    end

    -- Wait a moment so the loading screen is gone and the talent info is ready
    C_Timer.After(1.5, function()
        ns.ShowBuildReminder(place)
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
    OnEnteringWorld(isReloadingUi)
end)