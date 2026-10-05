local addonName, ns = ...

local REQUIRE_CONFIRM = false   -- set to true to get a "Are you sure?" popup first
local debugMode = false
local allX = {}

StaticPopupDialogs["TALENTX_CONFIRM_DELETE"] = {
    text = "Delete talent loadout \"%s\"?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, configID)
        C_ClassTalents.DeleteConfig(configID)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local MAX_UNDO = 5

-- Stores an export string of the loadout so it can be restored later
local function SaveForUndo(configID, name)
    local ok, str = pcall(C_Traits.GenerateImportString, configID)
    if not ok or type(str) ~= "string" or str == "" then
        return false
    end

    TalentXDB.deleted = TalentXDB.deleted or {}
    table.insert(TalentXDB.deleted, 1, {
        name = name,
        importString = str,
        specID = PlayerUtil.GetCurrentSpecID(),
        time = time(),
    })
    while #TalentXDB.deleted > MAX_UNDO do
        table.remove(TalentXDB.deleted)
    end
    return true
end

local function DeleteLoadout(configID, name)
    if InCombatLockdown() then
        print("|cffff4040TalentX:|r can't delete loadouts in combat.")
        return
    end

    if SaveForUndo(configID, name) then
        C_ClassTalents.DeleteConfig(configID)
        print("TalentX: deleted \"" .. name .. "\" (backup saved)")
    else
        print("|cffff4040TalentX:|r couldn't back up \"" .. name .. "\", so it was NOT deleted.")
    end
end

local function SetCrossTexture(tex)
    if C_Texture.GetAtlasInfo("common-icon-redx") then
        tex:SetAtlas("common-icon-redx")
    else
        tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    end
end

-- Menu rows are recycled, so create the X once per row and hide it when the row is released.
local function GetDeleteButton(row)
    if row.TalentXDelete then return row.TalentXDelete end

    local x = CreateFrame("Button", nil, row)
    table.insert(allX, x)
    x:SetSize(18, 18)
    x:SetHitRectInsets(-4, -4, -2, -2)
    x:SetPoint("RIGHT", row, "RIGHT", -20, 0)
    x:SetFrameLevel(row:GetFrameLevel() + 5)

    local icon = x:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    SetCrossTexture(icon)
    icon:SetAlpha(0.75)
    x.icon = icon

    -- brightens the cross on hover
    local glow = x:CreateTexture(nil, "HIGHLIGHT")
    glow:SetAllPoints()
    SetCrossTexture(glow)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.6)

    x:SetScript("OnEnter", function(self)
        self.icon:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Delete loadout", 1, 0.1, 0.1)
        if self.loadoutName then
            GameTooltip:AddLine(self.loadoutName, 1, 1, 1)
        end
        if TalentXDB and TalentXDB.altClick then
            GameTooltip:AddLine("Alt + Left-click to delete", 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)
    x:SetScript("OnLeave", function(self)
        self.icon:SetAlpha(0.75)
        GameTooltip:Hide()
    end)

    row:HookScript("OnHide", function() x:Hide() end)
    row.TalentXDelete = x
    return x
end

Menu.ModifyMenu("MENU_CLASS_TALENT_PROFILE", function(owner, rootDescription, contextData)
    -- Hide every X first; only real loadout rows turn theirs back on below
    for _, b in ipairs(allX) do b:Hide() end

    -- Build lookups of this spec's loadouts
    local nameByID, idByName = {}, {}
    local specID = PlayerUtil.GetCurrentSpecID()
    local starterID = Constants and Constants.TraitConsts and Constants.TraitConsts.STARTER_BUILD_TRAIT_CONFIG_ID

    -- Currently selected loadout (protected from the X). pcall keeps a failure here from breaking the menu.
    local okActive, activeID = pcall(C_ClassTalents.GetLastSelectedSavedConfigID, specID)
    if not okActive then activeID = nil end

    for _, id in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID) or {}) do
        if id ~= starterID then
            local info = C_Traits.GetConfigInfo(id)
            if info and info.name then
                nameByID[id] = info.name
                idByName[info.name] = id
            end
        end
    end

    for index, desc in rootDescription:EnumerateElementDescriptions() do
        ---@cast desc any

        if debugMode then
            print("TalentX row", index, tostring(desc.text), tostring(desc.data), "active:", tostring(activeID))
        end

        -- Prefer the configID if the row carries it, otherwise match by name
        local configID
        if type(desc.data) == "number" and nameByID[desc.data] then
            configID = desc.data
        elseif desc.text then
            configID = idByName[desc.text]
        end

        if configID and configID ~= activeID then
            local name = nameByID[configID]
            desc:AddInitializer(function(row, description, menu)
                local x = GetDeleteButton(row)
                x.loadoutName = name
                x:SetScript("OnClick", function()
                    if TalentXDB.altClick and not IsAltKeyDown() then
                        print("|cffff4040TalentX:|r hold Alt and Left-click to delete.")
                        return
                    end
                    GameTooltip:Hide()
                    DeleteLoadout(configID, name)
                    if menu and menu.Close then menu:Close() end
                end)
                x:Show()
            end)
        elseif desc.AddInitializer then
            -- Not a deletable loadout (Starter Build, New Loadout, Import, Share, active loadout):
            -- make sure no leftover X from a recycled row is visible.
            desc:AddInitializer(function(row)
                if row.TalentXDelete then
                    row.TalentXDelete:Hide()
                end
            end)
        end
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    TalentXDB = TalentXDB or {}
    if TalentXDB.altClick == nil then
        TalentXDB.altClick = true
    end
end)

local function RestoreLast()
    local list = TalentXDB and TalentXDB.deleted
    if not list or #list == 0 then
        print("TalentX: nothing to undo.")
        return
    end
    if InCombatLockdown() then
        print("|cffff4040TalentX:|r can't restore loadouts in combat.")
        return
    end

    local entry = list[1]
    if entry.specID ~= PlayerUtil.GetCurrentSpecID() then
        print("|cffff4040TalentX:|r \"" .. entry.name .. "\" belongs to a different spec. Switch to it first.")
        return
    end
    if not C_ClassTalents.CanCreateNewConfig() then
        print("|cffff4040TalentX:|r no free loadout slot. Delete another loadout first.")
        return
    end

    -- Blizzard's talent window has to be open/loaded for its import code to exist
    local frame = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if not (frame and frame.ImportLoadout) then
        print("|cffff4040TalentX:|r open the talents window (N) and try again.")
        return
    end

    local ok, result = pcall(frame.ImportLoadout, frame, entry.importString, entry.name)
    if ok and result then
        table.remove(list, 1)
        print("TalentX: restored \"" .. entry.name .. "\".")
    elseif ok then
        print("TalentX: Blizzard's import didn't report success. Check your loadout list for \"" .. entry.name .. "\".")
    else
        print("|cffff4040TalentX:|r restore failed: " .. tostring(result))
    end
end

SLASH_TALENTX1 = "/talentx"
SlashCmdList["TALENTX"] = function(msg)
    msg = (msg or ""):lower()
    TalentXDB = TalentXDB or {}

    if msg == "alt" then
        TalentXDB.altClick = not TalentXDB.altClick
        print("TalentX: Alt+Left-click required:", TalentXDB.altClick and "ON" or "OFF")
    elseif msg == "undo" then
        RestoreLast()
    elseif msg == "options" then
        if ns.OpenOptions then ns.OpenOptions() end
    elseif msg == "debug" then
        debugMode = not debugMode
        print("TalentX debug:", debugMode and "on" or "off")
    else
        print("TalentX commands: /talentx alt, /talentx debug")
    end
end