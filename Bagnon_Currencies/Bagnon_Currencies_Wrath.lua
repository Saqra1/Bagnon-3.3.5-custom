-- Bagnon Currencies 2.0 Classic

-- if WOW_PROJECT_ID ~= 11 then
-- 	return {}
-- end

local ToolTipCursorPosition = {x = 10, y = -4}
local ToolTipFont = GameFontNormal:GetFont()

local function CreateToolTip(width, height)
	-- In 3.3.5a, frames support backdrops without a template.
	local newTooltip = CreateFrame("Frame", nil, UIParent)
	newTooltip:SetWidth(width)
	newTooltip:SetHeight(height)
	newTooltip:Hide()
	newTooltip:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	newTooltip:SetBackdropColor(0, 0, 0, 1)
	newTooltip:RegisterForDrag("LeftButton")
	newTooltip:EnableMouse(true)
	newTooltip:SetResizable(true)


	newTooltip:SetScript("OnDragStart", function(self)
		self:StartSizing()
	end)
	newTooltip:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	return newTooltip;
end

function AddHeaderText(targetFrame, name)
	local font_size = 14

	if not targetFrame["header" .. name] then
		ToolTipCursorPosition.y = ToolTipCursorPosition.y - font_size
		targetFrame["header" .. name] = targetFrame:CreateFontString(nil,"ARTWORK")
		targetFrame["header" .. name]:SetFont(ToolTipFont, font_size, "OUTLINE")
		targetFrame["header" .. name]:SetPoint("CENTER", targetFrame, "TOP", 0, ToolTipCursorPosition.y) -- Anchor of the text is in the center, and its centered in its parent.
		ToolTipCursorPosition.y = ToolTipCursorPosition.y - font_size
	end

	targetFrame["header" .. name]:SetText("\124cffffcc00" .. name)
end

function AddCurrencyText(targetFrame, name, amount, iconPath, itemID)
	-- Add the currency Name

	if not targetFrame["currency" .. name] then
		targetFrame["currency" .. name] = targetFrame:CreateFontString(nil, "ARTWORK")
		targetFrame["currency" .. name]:SetFont(ToolTipFont, 13, "OUTLINE")
		targetFrame["currency" .. name]:SetPoint("TOPLEFT", targetFrame, "TOPLEFT", ToolTipCursorPosition.x, ToolTipCursorPosition.y)
	end

	targetFrame["currency" .. name]:SetText(name)

	if not targetFrame["currencyIcon" .. name] then
		targetFrame["currencyIcon" .. name] = targetFrame:CreateFontString(nil, "ARTWORK")
		targetFrame["currencyIcon" .. name]:SetFont(ToolTipFont, 13, "OUTLINE")
		targetFrame["currencyIcon" .. name]:SetPoint("TOPRIGHT", targetFrame, "TOPRIGHT", -10, ToolTipCursorPosition.y)

		local newCurrencyFrameWidth = targetFrame["currency" .. name]:GetWidth()
		local targetFrameWidth = targetFrame:GetWidth()

		if targetFrameWidth < (newCurrencyFrameWidth + 100) then
			targetFrame:SetWidth(newCurrencyFrameWidth + 100)
		end

		ToolTipCursorPosition.y = ToolTipCursorPosition.y - 13
		targetFrame:SetHeight(math.abs(ToolTipCursorPosition.y) + 2 + 10)
	end

	-- TODO: Find a solution to show Honor-point icon properly
	targetFrame["currencyIcon" .. name]:SetText(amount .. " |T" .. iconPath .. ":0|t")

end

function CreateLDBCurrencyString()
	local items = {}
	for i = 1, GetCurrencyListSize() do
		-- name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(index)
		local _, _, _, _, isWatched, count, extraCurrencyType, icon, _ = GetCurrencyListInfo(i)
		
		if isWatched then
			if extraCurrencyType == 1 then -- Arena Points
				icon = "Interface\\PvpFrame\\PVP-ArenaPoints-Icon"
			elseif extraCurrencyType == 2 then -- Honor Points
				icon = "Interface\\TargetingFrame\\UI-PVP-Alliance"
			end

			table.insert(items, {
				count = count,
				extraCurrencyType = extraCurrencyType,
				icon = icon
			})
		end
	end
	
	table.sort(items, function(x, y)
		return x.extraCurrencyType < y.extraCurrencyType 
	end)
	
	local LDBString = ""
	for _, item in ipairs(items) do
		local formatStr = "    %d |T%s%s|t"
		if item.count > 9999 then
			formatStr = "    %dk |T%s%s|t"
			item.count = item.count / 1000
		end

		local parameters = ":16"
		if item.extraCurrencyType == 2 then
			-- tCoordLeft = 0.05, tCoordRight = 0.65, tCoordTop = 0, tCoordBottom = 0.6
			parameters = ":16:16:0:0:100:100:12:65:0:60"
		end
	
		local currencyStr = string.format(formatStr, item.count , item.icon, parameters)
		LDBString = LDBString .. currencyStr
	end

	if LDBString == "" then
		return "Click here to set up Currencies";
	end

	return LDBString 
end

local ldb = _G.LibStub:GetLibrary("LibDataBroker-1.1");

local function ToggleCurrencyTab()
	_G.ToggleCharacter("TokenFrame")
end

-- The object used to show the currencies in the bag
local dataObject = ldb:NewDataObject("Bagnon_Currencies", {
	type = "Launcher",
	text = "Loading currencies...",
	OnClick = function() ToggleCurrencyTab() end
});

-- Tooltip
local ToolTip = CreateToolTip(100,200)
function tooltip_painter ()
	for i = 1, GetCurrencyListSize() do
		local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(i)
		if isHeader then
			AddHeaderText(ToolTip, name)
		else
			if extraCurrencyType == 1 then
				icon = "Interface\\PvpFrame\\PVP-ArenaPoints-Icon"
			elseif extraCurrencyType == 2 then
				icon = "Interface\\TargetingFrame\\UI-PVP-Alliance"
			end
			AddCurrencyText(ToolTip, name, count, icon, itemID)
		end
	end
end


dataObject.text = CreateLDBCurrencyString();

-- Events
function dataObject:OnEnter ()
	tooltip_painter()
	ToolTip:SetParent(self)
	ToolTip:SetPoint("BOTTOMLEFT",0,20)
	ToolTip:SetFrameStrata("TOOLTIP")
	ToolTip:Show()
end

function dataObject:OnLeave ()
	ToolTip:Hide()
end

function UpdateDataObject()
	dataObject.text = CreateLDBCurrencyString();
end

local frame = CreateFrame("FRAME", "Bagnon_Currencies_EventFrame");

local function eventHandler(self, event, ...)

	if event == "CURRENCY_DISPLAY_UPDATE" then
		UpdateDataObject()
	end
end
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE");
frame:SetScript("OnEvent", eventHandler);


-- We use this as an event to tell us that the tracked currencies have changed, and needs re-render
local function TrackedCurrenciesChanged()
	UpdateDataObject()
	-- We dont need to update the tooltip since that is updated every time its being shown
	-- TODO: Maybe we should update the tooltip here since people may be getting currency while the tooltip is shown....
end
hooksecurefunc("SetCurrencyBackpack", TrackedCurrenciesChanged)
