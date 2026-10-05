local addonName, ns = ...

-- Empty settings page for now; controls come in the next steps
local panel = CreateFrame("Frame")
panel.name = "TalentX"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("TalentX")

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

function ns.OpenOptions()
    Settings.OpenToCategory(category:GetID())
end