local addonName, ns = ...

-- Look and feel: change these values to restyle the menu
local PADDING     = 6
local MENU_MIN_W  = 200
local ACTION_W    = 38    -- room kept at the right of every row for the delete X

local COLOR_BG      = { 0.07, 0.07, 0.08, 0.96 }
local COLOR_BORDER  = { 0.25, 0.25, 0.28, 1 }
local COLOR_HOVER   = { 1, 1, 1, 0.08 }
local COLOR_LINE    = { 1, 1, 1, 0.08 }
local COLOR_TEXT    = { 0.92, 0.92, 0.92 }
local COLOR_MUTED   = { 0.55, 0.55, 0.60 }
local COLOR_ACTIVE  = { 1, 0.82, 0 }       -- the loadout you are on
local COLOR_STARTER = { 0, 0.77, 1 }       -- the Starter Build

local fontPath = GameFontNormal:GetFont()

-- A transparent full-screen button behind the menu: clicking anywhere else closes it
local catcher = CreateFrame("Button", nil, UIParent)
catcher:SetAllPoints(UIParent)
catcher:SetFrameStrata("FULLSCREEN")
catcher:RegisterForClicks("AnyUp")
catcher:Hide()

-- The menu panel
local menu = CreateFrame("Frame", "TalentXMenu", UIParent, "BackdropTemplate")
menu:SetFrameStrata("FULLSCREEN_DIALOG")
menu:SetClampedToScreen(true)
menu:EnableMouse(true)
menu:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
menu:SetBackdropColor(unpack(COLOR_BG))
menu:SetBackdropBorderColor(unpack(COLOR_BORDER))
menu:Hide()
tinsert(UISpecialFrames, "TalentXMenu") -- Esc closes it

catcher:SetScript("OnClick", function() menu:Hide() end)
menu:SetScript("OnShow", function() catcher:Show() end)
menu:SetScript("OnHide", function() catcher:Hide() end)

-- Header and the line under it
local header = menu:CreateFontString(nil, "OVERLAY")
header:SetFont(fontPath, 11, "")
header:SetPoint("TOPLEFT", menu, "TOPLEFT", PADDING + 6, -(PADDING + 3))
header:SetText("TALENT LOADOUTS")
header:SetTextColor(unpack(COLOR_MUTED))

local headerLine = menu:CreateTexture(nil, "ARTWORK")
headerLine:SetColorTexture(unpack(COLOR_LINE))
headerLine:SetHeight(1)
headerLine:SetPoint("TOPLEFT", menu, "TOPLEFT", PADDING, -(PADDING + 20))
headerLine:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -PADDING, -(PADDING + 20))

local LIST_TOP = PADDING + 24

-- Hidden text used to measure how wide the menu has to be
local measure = menu:CreateFontString(nil, "OVERLAY")
measure:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, 0)
measure:SetAlpha(0)

-- The red X texture (falls back to the ready-check cross if the atlas is missing)
local function SetCrossTexture(tex)
    if C_Texture.GetAtlasInfo("common-icon-redx") then
        tex:SetAtlas("common-icon-redx")
    else
        tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    end
end

-- Rows are created once and reused every time the menu opens
local rows = {}

local function GetRow(index)
    local row = rows[index]
    if row then return row end

    row = CreateFrame("Button", nil, menu)

    row.hover = row:CreateTexture(nil, "BACKGROUND")
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(unpack(COLOR_HOVER))
    row.hover:Hide()

    row.marker = row:CreateTexture(nil, "ARTWORK")
    row.marker:SetWidth(3)
    row.marker:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)
    row.marker:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 4)

    row.text = row:CreateFontString(nil, "OVERLAY")
    row.text:SetFont(fontPath, 13, "")
    row.text:SetPoint("LEFT", row, "LEFT", 12, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -ACTION_W, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)

    -- Keep the row highlighted while the mouse is over the row or the X inside it
    local function UpdateHover()
        if row:IsMouseOver() then
            row.hover:Show()
        else
            row.hover:Hide()
        end
    end
    row:SetScript("OnEnter", UpdateHover)
    row:SetScript("OnLeave", UpdateHover)

    -- The red X that deletes the loadout
    local del = CreateFrame("Button", nil, row)
    del:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    del:SetHitRectInsets(-4, -4, -4, -4)
    del:SetFrameLevel(row:GetFrameLevel() + 5)

    del.icon = del:CreateTexture(nil, "OVERLAY")
    del.icon:SetAllPoints()
    SetCrossTexture(del.icon)
    del.icon:SetAlpha(0.7)

    local glow = del:CreateTexture(nil, "HIGHLIGHT")
    glow:SetAllPoints()
    SetCrossTexture(glow)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.6)

    del:SetScript("OnEnter", function(self)
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
    del:SetScript("OnLeave", function(self)
        self.icon:SetAlpha(0.7)
        GameTooltip:Hide()
        UpdateHover()
    end)
    del:SetScript("OnClick", function()
        if TalentXDB and TalentXDB.altClick and not IsAltKeyDown() then
            print("|cffff4040TalentX:|r hold Alt and Left-click to delete.")
            return
        end
        GameTooltip:Hide()
        menu:Hide()
        if row.onDelete then row.onDelete() end
    end)
    del:Hide()
    row.del = del

    row:SetScript("OnClick", function(self)
        menu:Hide()
        if self.onClick then self.onClick() end
    end)

    rows[index] = row
    return row
end

-- The text settings from the options panel (with defaults)
local function GetTextSettings()
    local db = TalentXDB or {}
    return db.menuFontSize or 13,
           db.menuTextColor or COLOR_TEXT,
           db.menuActiveColor or COLOR_ACTIVE
end

-- Opens the menu next to the given frame (the tracker bar)
function ns.ShowLoadoutMenu(owner)
    local specID = PlayerUtil.GetCurrentSpecID()
    if not specID then return end

    local fontSize, textColor, activeColor = GetTextSettings()
    local rowHeight = fontSize + 13
    local widest = 0

    local okActive, activeID = pcall(C_ClassTalents.GetLastSelectedSavedConfigID, specID)
    if not okActive then activeID = nil end
    local starterActive = C_ClassTalents.GetStarterBuildActive and C_ClassTalents.GetStarterBuildActive()

    -- Collect this spec's loadouts, then the Starter Build
    local entries = {}
    for _, id in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID) or {}) do
        local info = C_Traits.GetConfigInfo(id)
        if info and info.name then
            entries[#entries + 1] = {
                id = id,
                name = info.name,
                active = (not starterActive) and activeID == id,
            }
        end
    end
    if C_ClassTalents.GetHasStarterBuild and C_ClassTalents.GetHasStarterBuild() then
        entries[#entries + 1] = {
            id = ns.STARTER_BUILD_ID,
            name = "Starter Build",
            active = starterActive and true or false,
            starter = true,
        }
    end

    if #entries == 0 then
        print("|cffff4040TalentX:|r no loadouts to show for this spec.")
        return
    end

    -- Fill the rows
    for i, entry in ipairs(entries) do
        local row = GetRow(i)
        local y = -(LIST_TOP + (i - 1) * rowHeight)
        row:SetHeight(rowHeight)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", PADDING, y)
        row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -PADDING, y)

        row.text:SetFont(fontPath, fontSize, "")
        row.text:SetText(entry.name)

        measure:SetFont(fontPath, fontSize, "")
        measure:SetText(entry.name)
        widest = math.max(widest, measure:GetStringWidth())

        -- Your colours apply to loadouts; the Starter Build always stays blue
        local color = textColor
        if entry.starter then
            color = COLOR_STARTER
        elseif entry.active then
            color = activeColor
        end
        row.text:SetTextColor(color[1], color[2], color[3])

        if entry.active then
            local markerColor = entry.starter and COLOR_STARTER or activeColor
            row.marker:SetColorTexture(markerColor[1], markerColor[2], markerColor[3], 1)
            row.marker:Show()
        else
            row.marker:Hide()
        end

        row.hover:Hide()
        row.onClick = function() ns.SwitchToLoadout(entry.id, entry.name) end

        -- The red X: not on the loadout you are on (it is protected) and not on the Starter Build
        local canDelete = (not entry.active) and (not entry.starter)
        local xSize = math.max(14, math.floor(fontSize * 1.2))
        row.del:SetSize(xSize, xSize)
        row.del.loadoutName = entry.name
        row.del.icon:SetAlpha(0.7)
        row.del:SetShown(canDelete)
        if canDelete then
            row.onDelete = function() ns.DeleteLoadout(entry.id, entry.name) end
        else
            row.onDelete = nil
        end

        row:Show()
    end
    for i = #entries + 1, #rows do
        rows[i]:Hide()
    end

    -- Size and place the panel: under the bar, or above it when the bar sits low on screen
    -- Wide enough for the longest name, plus the room kept for the red X
    local width = math.max(MENU_MIN_W, owner:GetWidth(), widest + 12 + ACTION_W + PADDING * 2 + 4)
    menu:SetSize(width, LIST_TOP + #entries * rowHeight + PADDING)
    menu:ClearAllPoints()
    local _, centerY = owner:GetCenter()
    if centerY and centerY < UIParent:GetHeight() / 2 then
        menu:SetPoint("BOTTOMLEFT", owner, "TOPLEFT", 0, 4)
    else
        menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -4)
    end
    menu:Show()
end