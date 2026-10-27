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

-- Saving and restoring position and size (stored in TalentXDB.tracker)
local function SaveBarPosition()
    TalentXDB = TalentXDB or {}
    local point, _, relPoint, x, y = bar:GetPoint()
    TalentXDB.tracker = {
        point = point,
        relPoint = relPoint,
        x = x,
        y = y,
        width = bar:GetWidth(),
        height = bar:GetHeight(),
    }
end

local function RestoreBar()
    local s = TalentXDB and TalentXDB.tracker
    if not s then return end
    bar:ClearAllPoints()
    bar:SetPoint(s.point or "CENTER", UIParent, s.relPoint or "CENTER", s.x or 0, s.y or 200)
    bar:SetSize(s.width or 220, s.height or 28)
end

-- Dragging: hold the left mouse button on the bar and move it. A plain click opens the loadout menu.
local dragged = false

bar:SetMovable(true)
bar:SetClampedToScreen(true)
bar:EnableMouse(true)
bar:RegisterForDrag("LeftButton")
bar:SetScript("OnDragStart", function(self)
    dragged = true
    if TalentXDB and TalentXDB.trackerLocked then return end
    self:StartMoving()
end)
bar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveBarPosition()
end)
bar:SetScript("OnMouseDown", function()
    dragged = false
end)
bar:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and not dragged then
        ns.OpenLoadoutMenu(self)
    end
end)

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
    SaveBarPosition()
end)

-- The loadout name shown on the bar
local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")
text:SetText("Loading...")
bar.text = text

-- Keep the text sized to the bar
local fontPath = GameFontNormal:GetFont()
text:SetWordWrap(false)

local function ApplySize(self, width, height)
    text:SetWidth(width - 16)
    text:SetFont(fontPath, math.max(8, math.floor(height * 0.5)), "")
end
bar:SetScript("OnSizeChanged", ApplySize)
ApplySize(bar, bar:GetWidth(), bar:GetHeight())

-- Applies the saved options: shown or hidden, locked or unlocked, background opacity
function ns.ApplyTrackerSettings()
    local db = TalentXDB or {}
    local locked = db.trackerLocked == true
    bar:SetShown(db.trackerShown ~= false)
    bar:EnableMouse(true)
    grip:SetShown(not locked)
    bar:SetBackdropColor(0, 0, 0, db.trackerOpacity or 0.6)
end

-- Puts the bar back at its default position and size
function ns.ResetTracker()
    if TalentXDB then TalentXDB.tracker = nil end
    bar:ClearAllPoints()
    bar:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    bar:SetSize(220, 28)
end

-- Checks whether a config ID is one of this spec's saved loadouts
local function IsSavedLoadout(specID, configID)
    for _, id in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID) or {}) do
        if id == configID then return true end
    end
    return false
end

-- Works out what the bar should say. Returns the text and a state:
-- "ok", "starter", "none" (no loadout selected), "empty" (no saved loadouts yet) or "unknown"
local function GetActiveLoadoutState()
    local specID = PlayerUtil.GetCurrentSpecID()
    if not specID then return "No spec", "unknown" end

    -- Starter Build has no saved loadout of its own
    if C_ClassTalents.GetStarterBuildActive and C_ClassTalents.GetStarterBuildActive() then
        return "Starter Build", "starter"
    end

    -- No saved loadouts at all (also what we see before the game has loaded the list)
    local list = C_ClassTalents.GetConfigIDsBySpecID(specID) or {}
    if #list == 0 then return "No saved loadouts", "empty" end

    local ok, configID = pcall(C_ClassTalents.GetLastSelectedSavedConfigID, specID)
    if not ok then return "Unknown loadout", "unknown" end
    if configID == -2 then return "Starter Build", "starter" end

    -- Nothing stored, or the stored loadout is no longer in the list
    if not configID or not IsSavedLoadout(specID, configID) then
        return "No loadout selected", "none"
    end

    local info = C_Traits.GetConfigInfo(configID)
    if info and info.name then return info.name, "ok" end
    return "Unknown loadout", "unknown"
end

local lastState

function ns.UpdateTracker()
    local name, state = GetActiveLoadoutState()
    bar.text:SetText(name)

    if state == "none" then
        bar.text:SetTextColor(1, 0.1, 0.1)
        -- Alert once each time the "none" state begins
        if lastState ~= "none" then
            print("|cffff4040TalentX:|r no talent loadout is selected.")
            UIErrorsFrame:AddMessage("No talent loadout selected", 1, 0.1, 0.1)
        end
    elseif state == "starter" then
        -- Same blue as "Starter Build" in the loadout menu
        bar.text:SetTextColor(0, 0.77, 1)
    else
        bar.text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    end

    lastState = state
end

-- The Starter Build's config ID (the game uses -2 for it)
local STARTER_BUILD_ID = (Constants and Constants.TraitConsts and Constants.TraitConsts.STARTER_BUILD_TRAIT_CONFIG_ID) or -2

-- Switches to a saved loadout or the Starter Build by its config ID (out of combat only)
local function SwitchToLoadout(configID, name)
    if InCombatLockdown() then
        print("|cffff4040TalentX:|r you can't change talents in combat.")
        return
    end

    local specID = PlayerUtil.GetCurrentSpecID()
    if not specID then return end

    -- Preferred: let Blizzard's own talents code do the switch, so the starter
    -- build flag, the talents window dropdown and the selection all stay in sync
    if not PlayerSpellsFrame then
        pcall(C_AddOns.LoadAddOn, "Blizzard_PlayerSpells")
    end
    local frame = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if frame and frame.LoadConfigInternal then
        if pcall(frame.LoadConfigInternal, frame, configID, true) then
            C_Timer.After(0.3, ns.UpdateTracker)
            return
        end
    end

    -- Fallback: the game's own calls (the talents window won't know about the switch)
    local ok, result
    if configID == STARTER_BUILD_ID then
        ok, result = pcall(C_ClassTalents.SetStarterBuildActive, true)
    else
        ok, result = pcall(C_ClassTalents.LoadConfig, configID, true)
    end

    if not ok then
        print("|cffff4040TalentX:|r couldn't switch loadout: " .. tostring(result))
        return
    end
    if Enum.LoadConfigResult and result == Enum.LoadConfigResult.Error then
        print("|cffff4040TalentX:|r the game refused to load \"" .. name .. "\".")
        return
    end

    C_ClassTalents.UpdateLastSelectedSavedConfigID(specID, configID)
    if frame and frame.RefreshLoadoutOptions then
        pcall(frame.RefreshLoadoutOptions, frame)
    end
    C_Timer.After(0.3, ns.UpdateTracker)
end

-- Opens one of Blizzard's own loadout windows:
-- "ClassTalentLoadoutCreateDialog" (new loadout) or "ClassTalentLoadoutImportDialog" (import)
local function OpenBlizzardDialog(frameName)
    if InCombatLockdown() then
        print("|cffff4040TalentX:|r you can't change talents in combat.")
        return
    end
    if not C_ClassTalents.CanCreateNewConfig() then
        print("|cffff4040TalentX:|r no free loadout slot left.")
        return
    end

    -- Blizzard loads its talent window code on demand
    if not _G[frameName] then
        pcall(C_AddOns.LoadAddOn, "Blizzard_PlayerSpells")
    end

    local dialog = _G[frameName]
    if not dialog then
        print("|cffff4040TalentX:|r couldn't find " .. frameName)
        return
    end

    if dialog.ShowDialog then
        dialog:ShowDialog()
    elseif StaticPopupSpecial_Show then
        StaticPopupSpecial_Show(dialog)
    else
        dialog:Show()
    end
end

-- Share: a small box showing the loadout string, ready to copy with Ctrl+C
local shareString = ""

StaticPopupDialogs["TALENTX_SHARE_LOADOUT"] = {
    text = "Loadout string for \"%s\"\nPress Ctrl+C to copy it, then close this window.",
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self)
        local editBox = (self.GetEditBox and self:GetEditBox()) or self.editBox or self.EditBox
        if not editBox then return end
        editBox:SetText(shareString)
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    EditBoxOnEscapePressed = function(editBox)
        editBox:GetParent():Hide()
    end,
    EditBoxOnEnterPressed = function(editBox)
        editBox:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function ShareLoadout(configID, name)
    local str = C_Traits.GenerateImportString(configID)
    if not str or str == "" then
        print("|cffff4040TalentX:|r couldn't get a loadout string for " .. name)
        return
    end
    shareString = str
    StaticPopup_Show("TALENTX_SHARE_LOADOUT", name)
end

-- Opens a menu of this spec's loadouts
function ns.OpenLoadoutMenu(owner)
    local specID = PlayerUtil.GetCurrentSpecID()
    if not specID then return end

    local okActive, activeID = pcall(C_ClassTalents.GetLastSelectedSavedConfigID, specID)
    if not okActive then activeID = nil end
    local starterActive = C_ClassTalents.GetStarterBuildActive and C_ClassTalents.GetStarterBuildActive()

    MenuUtil.CreateContextMenu(owner, function(ownerRegion, rootDescription)
        rootDescription:CreateTitle("Talent loadouts")

        for _, id in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID) or {}) do
            local info = C_Traits.GetConfigInfo(id)
            local name = info and info.name
            if name then
                rootDescription:CreateRadio(name,
                    function() return (not starterActive) and activeID == id end,
                    function() SwitchToLoadout(id, name) end)
            end
        end

        if C_ClassTalents.GetHasStarterBuild and C_ClassTalents.GetHasStarterBuild() then
            rootDescription:CreateRadio("|cff00c4feStarter Build|r",
                function() return starterActive end,
                function() SwitchToLoadout(STARTER_BUILD_ID, "Starter Build") end)
        end

        rootDescription:CreateDivider()

        local canCreate = C_ClassTalents.CanCreateNewConfig()

        local importButton = rootDescription:CreateButton(TALENT_FRAME_DROP_DOWN_IMPORT or "Import",
            function() OpenBlizzardDialog("ClassTalentLoadoutImportDialog") end)

        -- Greyed out when there is no free loadout slot
        if not canCreate then
            importButton:SetEnabled(false)
        end


        -- Share: a submenu with one entry per loadout
        local shareButton = rootDescription:CreateButton(TALENT_FRAME_DROP_DOWN_EXPORT or "Share")
        local hasLoadouts = false
        for _, id in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID) or {}) do
            local info = C_Traits.GetConfigInfo(id)
            local name = info and info.name
            if name then
                hasLoadouts = true
                shareButton:CreateButton(name, function() ShareLoadout(id, name) end)
            end
        end
        if not hasLoadouts then
            shareButton:SetEnabled(false)
        end
    end)
end

-- Refresh whenever something about talents changes; restore the saved layout at login
bar:RegisterEvent("PLAYER_LOGIN")
bar:RegisterEvent("PLAYER_ENTERING_WORLD")
bar:RegisterEvent("TRAIT_CONFIG_UPDATED")
bar:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
bar:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
bar:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        RestoreBar()
        ns.ApplyTrackerSettings()
    end
    C_Timer.After(0.3, ns.UpdateTracker)
end)