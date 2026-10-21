-- Bagnon Currencies by Spillmaker, adapted for the original WoW 3.3.5a client.

local ToolTipFont = GameFontNormal:GetFont()
local MAX_WATCHED_CURRENCIES = 3 -- Blizzard_TokenUI's MAX_WATCHED_TOKENS.

local function CurrencyTexture(extraCurrencyType, icon, size)
	if extraCurrencyType == 1 then
		icon = "Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
	elseif extraCurrencyType == 2 then
		local faction = UnitFactionGroup("player")
		if faction then
			icon = "Interface\\PVPFrame\\PVP-Currency-" .. faction
		end
	end

	if not icon or icon == "" then
		return ""
	end
	return string.format(" |T%s:%d:%d|t", icon, size, size)
end

local function CreateLDBCurrencyString()
	local items = {}
	-- The backpack API includes watched currencies inside collapsed categories.
	for i = 1, MAX_WATCHED_CURRENCIES do
		local name, count, extraCurrencyType, icon = GetBackpackCurrencyInfo(i)
		if name then
			table.insert(items, {count = count, kind = extraCurrencyType, icon = icon, index = i})
		end
	end

	table.sort(items, function(x, y)
		if x.kind == y.kind then
			return x.index < y.index
		end
		return x.kind < y.kind
	end)

	local text = {}
	for _, item in ipairs(items) do
		local count = tostring(item.count)
		if item.count > 9999 then
			count = string.format("%dk", math.floor(item.count / 1000))
		end
		table.insert(text, "    " .. count .. CurrencyTexture(item.kind, item.icon, 16))
	end

	if #text == 0 then
		return "Click here to set up Currencies"
	end
	return table.concat(text)
end

-- Frames in 3.3.5a have backdrop methods without BackdropTemplate.
local ToolTip = CreateFrame("Frame", nil, UIParent)
ToolTip:SetWidth(100)
ToolTip:SetHeight(20)
ToolTip:SetFrameStrata("TOOLTIP")
ToolTip:Hide()
ToolTip:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4},
})
ToolTip:SetBackdropColor(0, 0, 0, 1)

local rows = {}
local function PaintToolTip()
	local y, width, usedRows = -10, 100, 0
	for i = 1, GetCurrencyListSize() do
		local name, isHeader, _, _, _, count, kind, icon = GetCurrencyListInfo(i)
		if name and name ~= "" then
			usedRows = usedRows + 1
			local row = rows[usedRows]
			if not row then
				row = {
					label = ToolTip:CreateFontString(nil, "ARTWORK"),
					value = ToolTip:CreateFontString(nil, "ARTWORK"),
				}
				row.value:SetFont(ToolTipFont, 13, "OUTLINE")
				rows[usedRows] = row
			end

			row.label:ClearAllPoints()
			row.value:ClearAllPoints()
			row.label:Show()
			if isHeader then
				row.label:SetFont(ToolTipFont, 14, "OUTLINE")
				row.label:SetPoint("TOP", ToolTip, "TOP", 0, y)
				row.label:SetText("|cffffcc00" .. name .. "|r")
				row.value:Hide()
				width = math.max(width, row.label:GetStringWidth() + 20)
				y = y - 22
			else
				row.label:SetFont(ToolTipFont, 13, "OUTLINE")
				row.label:SetPoint("TOPLEFT", ToolTip, "TOPLEFT", 10, y)
				row.label:SetText(name)
				row.value:SetPoint("TOPRIGHT", ToolTip, "TOPRIGHT", -10, y)
				row.value:SetText(count .. CurrencyTexture(kind, icon, 16))
				row.value:Show()
				width = math.max(width, row.label:GetStringWidth() + row.value:GetStringWidth() + 30)
				y = y - 18
			end
		end
	end

	for i = usedRows + 1, #rows do
		rows[i].label:Hide()
		rows[i].value:Hide()
	end
	ToolTip:SetWidth(width)
	ToolTip:SetHeight(10 - y)
end

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataObject = ldb:NewDataObject("Bagnon_Currencies", {
	type = "data source",
	text = CreateLDBCurrencyString(),
	OnClick = function() ToggleCharacter("TokenFrame") end,
})

function dataObject:OnEnter()
	ToolTip:Hide()
	ToolTip:SetParent(self)
	ToolTip:ClearAllPoints()
	ToolTip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 6)
	PaintToolTip()
	ToolTip:Show()
end

function dataObject:OnLeave()
	if ToolTip:GetParent() == self then
		ToolTip:Hide()
	end
end

local function UpdateDataObject()
	dataObject.text = CreateLDBCurrencyString()
	if ToolTip:IsShown() then
		PaintToolTip()
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
frame:SetScript("OnEvent", UpdateDataObject)
hooksecurefunc("SetCurrencyBackpack", UpdateDataObject)
