local addonName, ns = ...

local debugMode = false
local allX = {}

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

    -- NEW (slider): limit comes from the saved setting
    local limit = TalentXDB.maxUndo or 5
    while #TalentXDB.deleted > limit do
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
    x:SetPoint("RIGHT", row, "RIGHT", -32, 0)
    x:SetFrameLevel(row:GetFrameLevel() + 5)

    local icon = x:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    SetCrossTexture(icon)
    icon:SetAlpha(0.75)
    x.icon = icon

    local glow = x:CreateTexture(nil, "HIGHLIGHT")
    glow:SetAllPoints()
    SetCrossTexture(glow)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.6)

    x:SetScript("OnEnter", function(self)
        self.icon:SetAlpha(1)
        if TalentXDB and TalentXDB.showTooltip == false then return end
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

    local frame = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if not (frame and frame.ImportLoadout) then
        print("|cffff4040TalentX:|r open the talents window (N) and try again.")
        return
    end

    local specID = entry.specID
    local before = #(C_ClassTalents.GetConfigIDsBySpecID(specID) or {})

    local ok, err = pcall(frame.ImportLoadout, frame, entry.importString, entry.name)
    if not ok then
        print("|cffff4040TalentX:|r restore failed: " .. tostring(err))
        return
    end

    -- Give the server a moment, then check a loadout was really created
    C_Timer.After(1, function()
        local after = #(C_ClassTalents.GetConfigIDsBySpecID(specID) or {})
        if after > before then
            for i, e in ipairs(list) do
                if e == entry then table.remove(list, i) break end
            end
            print("TalentX: restored \"" .. entry.name .. "\".")
            if frame.RefreshLoadoutOptions then pcall(frame.RefreshLoadoutOptions, frame) end
        else
            print("|cffff4040TalentX:|r the game did not create the loadout. Your backup of \"" .. entry.name .. "\" is still saved.")
        end
    end)
end

ns.RestoreLast = RestoreLast

Menu.ModifyMenu("MENU_CLASS_TALENT_PROFILE", function(owner, rootDescription, contextData)
    -- Hide every X first; only real loadout rows turn theirs back on below
    for _, b in ipairs(allX) do b:Hide() end

    local nameByID, idByName = {}, {}
    local specID = PlayerUtil.GetCurrentSpecID()
    local starterID = Constants and Constants.TraitConsts and Constants.TraitConsts.STARTER_BUILD_TRAIT_CONFIG_ID

    -- Currently selected loadout (protected from the X)
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
            desc:AddInitializer(function(row)
                if row.TalentXDelete then
                    row.TalentXDelete:Hide()
                end
            end)
        end
    end
end)

-- Defaults for saved settings
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    TalentXDB = TalentXDB or {}
    if TalentXDB.altClick == nil then
        TalentXDB.altClick = true
    end
    if TalentXDB.showTooltip == nil then
        TalentXDB.showTooltip = true
    end
    -- NEW (slider)
    if TalentXDB.maxUndo == nil then
        TalentXDB.maxUndo = 5
    end
end)

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
        print("TalentX commands: /talentx alt, undo, options, debug")
    end
end