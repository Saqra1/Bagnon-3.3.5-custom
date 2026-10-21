-- Run from the AddOns repository root with Lua 5.1; no WoW client required.
-- Optional arguments override the currency and broker files for regression probes.
assert(_VERSION == "Lua 5.1", "Run this check with Lua 5.1")
strmatch = string.match
-- WoW accepts UTF-8 BOMs in several existing Bagnon sources; stock Lua 5.1 does not.
local function loadLua(path)
	local file = assert(io.open(path, "rb"))
	local source = file:read("*a")
	file:close()
	if source:sub(1, 3) == "\239\187\191" then source = source:sub(4) end
	return assert(loadstring(source, "@" .. path))
end
local function dofile(path) return loadLua(path)() end
if arg[1] == "--syntax" then
	local count = 0
	for path in io.lines() do
		loadLua(path)
		count = count + 1
	end
	assert(count > 0, "Pipe Lua file paths into this check")
	print("PASS: Lua 5.1 syntax for " .. count .. " files (UTF-8 BOMs stripped for stock Lua)")
	return
end
local currencyFile = arg[1] or "Bagnon_Currencies/Bagnon_Currencies_Wrath.lua"
local brokerFile = arg[2] or "Bagnon/components/brokerDisplay.lua"

local frames, hooks = {}, {}
local methods = {}
local function textWidth(text)
	text = (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	local icons = 0
	text = text:gsub("|T.-:(%d+):%d+|t", function(size)
		icons = icons + tonumber(size)
		return ""
	end)
	return #text * 7 + icons
end
function methods:GetStringWidth() return textWidth(self.text) end
function methods:GetWidth()
	return self.width or (self.kind == "FontString" and self:GetStringWidth()) or 0
end
function methods:GetHeight() return self.height or 13 end
function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value) self.height = value end
function methods:SetText(value) self.text = tostring(value) end
function methods:SetFont() end
function methods:SetFontObject() end
function methods:SetJustifyH() end
function methods:SetNormalFontObject() end
function methods:SetHighlightFontObject() end
function methods:GetTextWidth() return self:GetStringWidth() end
function methods:GetTextHeight() return 13 end
function methods:SetTexture(value) self.texture = value end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:ClearAllPoints() self.points = {} end
function methods:SetParent(parent) self.parent = parent end
function methods:GetParent() return self.parent end
function methods:SetFrameStrata(value) self.strata = value end
function methods:SetBackdrop(value) self.backdrop = value end
function methods:SetBackdropColor() end
function methods:SetToplevel() end
function methods:SetID(id) self.id = id end
function methods:RegisterForClicks() end
function methods:RegisterForDrag() end
function methods:EnableMouse() end
function methods:SetResizable() end
function methods:EnableMouseWheel() end
function methods:SetHitRectInsets(...) self.insets = {...} end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:IsShown() return self.shown end
function methods:IsVisible()
	return self.shown and (not self.parent or self.parent:IsVisible())
end
local function setShown(frame, value)
	local visibility = {}
	for _, candidate in ipairs(frames) do
		visibility[candidate] = candidate:IsVisible()
	end
	frame.shown = value
	for _, candidate in ipairs(frames) do
		local visible = candidate:IsVisible()
		if visible ~= visibility[candidate] then
			local callback = candidate.scripts[visible and "OnShow" or "OnHide"]
			if callback then callback(candidate) end
		end
	end
end
function methods:Show() setShown(self, true) end
function methods:Hide() setShown(self, false) end
function CreateFrame(kind, name, parent, template)
	assert(template == nil, "Unexpected frame template: " .. tostring(template))
	local frame = setmetatable({
		kind = kind, parent = parent, shown = true,
		scripts = {}, events = {}, points = {}, fontStrings = {},
	}, {__index = methods})
	frames[#frames + 1] = frame
	if name then _G[name] = frame end
	return frame
end
function methods:CreateFontString()
	local fontString = CreateFrame("FontString", nil, self)
	self.fontStrings[#self.fontStrings + 1] = fontString
	return fontString
end
function methods:CreateTexture() return CreateFrame("Texture", nil, self) end
UIParent = CreateFrame("Frame")
GameFontNormal = {GetFont = function() return "Fonts\\FRIZQT__.TTF", 12 end}
GameTooltip = CreateFrame("GameTooltip", nil, UIParent)
function GameTooltip:SetOwner(owner) self.owner = owner end
function GameTooltip:IsOwned(owner) return self.owner == owner end
function GameTooltip:ClearLines() end
GameTooltip:Hide()

local dataReady, faction = false, "Horde"
local currencies = {
	{"Dungeon and Raid", true, true},
	{"Emblem of Triumph", false, false, false, true, 42, 0, "Interface\\Icons\\Emblem", 47241},
	{"Emblem of Frost", false, false, false, false, 20, 0, "Interface\\Icons\\Frost", 49426},
	{"Player vs. Player", true, true},
	{"Arena Points", false, false, false, true, 1250, 1},
	{"Honor Points", false, false, false, true, 12345, 2},
}
local function visibleCurrencies()
	local visible, expanded = {}, true
	if dataReady then
		for _, row in ipairs(currencies) do
			if row[2] then
				expanded = row[3]
				visible[#visible + 1] = row
			elseif expanded then
				visible[#visible + 1] = row
			end
		end
	end
	return visible
end
function GetCurrencyListSize() return #visibleCurrencies() end
function GetCurrencyListInfo(index)
	local row = visibleCurrencies()[index]
	if row then return unpack(row, 1, 9) end
end
function GetBackpackCurrencyInfo(index)
	assert(index >= 1 and index <= 3, "Invalid backpack currency slot")
	local watched = 0
	if dataReady then
		for _, row in ipairs(currencies) do
			if row[5] then
				watched = watched + 1
				if watched == index then return row[1], row[6], row[7], row[8], row[9] end
			end
		end
	end
end
function SetCurrencyBackpack(index, watch)
	local row = assert(visibleCurrencies()[index])
	row[5] = watch == 1
end
function UnitFactionGroup(unit) assert(unit == "player"); return faction end
function hooksecurefunc(name, callback)
	local original = assert(_G[name])
	hooks[name] = callback
	_G[name] = function(...)
		original(...)
		callback(...)
	end
end
local openedTab
function ToggleCharacter(tab) openedTab = tab end
local function fire(event)
	for _, frame in ipairs(frames) do
		if frame.events[event] then frame.scripts.OnEvent(frame, event) end
	end
end

dofile("Bagnon/libs/LibStub/LibStub.lua")
dofile("Bagnon/libs/CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("Bagnon/libs/LibDataBroker-1.1.lua")
local bagnon = {}
LibStub:NewLibrary("AceAddon-3.0", 1000).GetAddon = function(_, name)
	assert(name == "Bagnon")
	return bagnon
end
dofile("Bagnon/utility/classy.lua")
dofile("Bagnon/utility/ears.lua")
dofile("Bagnon/utility/callbacks.lua")
dofile("Bagnon/components/frameSettings.lua")
local savedFrames = {}
bagnon.SavedFrameSettings = {Get = function(_, id)
	savedFrames[id] = savedFrames[id] or {
		objectName = "Bagnon_Currencies",
		GetBrokerDisplayObject = function(self) return self.objectName end,
		SetBrokerDisplayObject = function(self, value) self.objectName = value end,
	}
	return savedFrames[id]
end}
dofile(brokerFile)
local ldb = LibStub("LibDataBroker-1.1")
local bag = CreateFrame("Frame", nil, UIParent)
local broker = bagnon.BrokerDisplay:New(1, "inventory", bag)
broker:SetWidth(500)
local globalsBefore = {}
for key, value in pairs(_G) do globalsBefore[key] = value end

-- Load the default manifest exactly as the original client does.
for _, manifest in ipairs({"Bagnon_Currencies.toc", "Bagnon_Currencies_Wrath.toc"}) do
	local count = 0
	for line in io.lines("Bagnon_Currencies/" .. manifest) do
		if line:match("^## Interface:") then
			assert(line:match("30300%s*$"), "Manifest must target 30300")
		end
		if line:match("^## Dependencies:") then
			assert(line:match("Bagnon%s*$"), "Bagnon must load before its plugin")
		end
		if line ~= "" and not line:match("^#") then
			local path = line:gsub("\\", "/")
			assert(not path:find("Mainline", 1, true), "Retail code must not load")
			loadLua("Bagnon_Currencies/" .. path)
			count = count + 1
			if manifest == "Bagnon_Currencies.toc" then
				dofile(path:match("_Wrath.lua$") and currencyFile or "Bagnon_Currencies/" .. path)
			end
		end
	end
	assert(count == 2, "Expected one library and one currency implementation")
end
local object = assert(ldb:GetDataObjectByName("Bagnon_Currencies"))
assert(object.text == "Click here to set up Currencies")
dataReady = true
fire("PLAYER_ENTERING_WORLD")
assert(object.text:find("42 |TInterface\\Icons\\Emblem", 1, true), "Login must refresh currencies")
assert(object.text:find("1250 |TInterface\\PVPFrame\\PVP-ArenaPoints-Icon", 1, true))
assert(object.text:find("12k |TInterface\\PVPFrame\\PVP-Currency-Horde", 1, true))
assert(broker.text.text == object.text, "Real LDB callback must update Bagnon")
print("PASS: manifests, delayed login data, legacy tuple, Horde icons, and Bagnon LDB updates")

broker:OnEnter()
local tooltip
for _, frame in ipairs(frames) do
	if frame.backdrop then assert(not tooltip); tooltip = frame end
end
assert(tooltip and tooltip:IsVisible() and tooltip.parent == broker)
local function findText(text)
	for _, fontString in ipairs(tooltip.fontStrings) do
		if fontString:IsShown() and fontString.text == text then return fontString end
	end
end
local function hasText(text) return findText(text) ~= nil end
assert(hasText("|cffffcc00Dungeon and Raid|r"))
assert(hasText("42 |TInterface\\Icons\\Emblem:16:16|t"))
local initialHeight, initialFonts = tooltip.height, #tooltip.fontStrings
currencies[2][6] = 43
fire("CURRENCY_DISPLAY_UPDATE")
assert(hasText("43 |TInterface\\Icons\\Emblem:16:16|t"), "Open tooltip must update")
assert(broker.text.text == object.text)

-- Folding the native list must not drop watched totals or retain old tooltip rows.
currencies[1][3] = false
broker:OnLeave()
broker:OnEnter()
fire("CURRENCY_DISPLAY_UPDATE")
assert(object.text:find("43 |TInterface\\Icons\\Emblem", 1, true), "Collapsed watched currency lost")
assert(not hasText("Emblem of Triumph"), "Collapsed rows must disappear")
assert(tooltip.height < initialHeight)
currencies[1][3] = true
-- Simulate moving a currency into another category and learning a new one.
local moved = table.remove(currencies, 2)
table.insert(currencies, 2, {"New token", false, false, false, false, 7, 0, "Interface\\Icons\\New", 999})
currencies[#currencies + 1] = {"Unused", true, true}
currencies[#currencies + 1] = moved
broker:OnLeave()
broker:OnEnter()
assert(hasText("New token") and hasText("Emblem of Triumph"))
assert(findText("New token").points[1][5] ~= findText("Emblem of Triumph").points[1][5],
	"New and moved currencies must occupy separate rows")
local expandedFonts = #tooltip.fontStrings
broker:OnLeave()
broker:OnEnter()
assert(#tooltip.fontStrings == expandedFonts, "Repeated hover must reuse rows")
assert(expandedFonts >= initialFonts)

local longName = string.rep("Long currency ", 12)
currencies[2][1], currencies[2][6] = longName, 123456789
fire("CURRENCY_DISPLAY_UPDATE")
local nameWidth = findText(longName):GetStringWidth()
local valueWidth = findText("123456789 |TInterface\\Icons\\New:16:16|t"):GetStringWidth()
assert(tooltip.width >= nameWidth + valueWidth + 30, "Tooltip columns overlap")
currencies[2][1], currencies[2][6] = "New token", 7
fire("CURRENCY_DISPLAY_UPDATE")
assert(tooltip.width < nameWidth, "Tooltip width must shrink when content shrinks")

-- Empty or missing icon paths must not abort the whole display.
moved[8] = nil
fire("CURRENCY_DISPLAY_UPDATE")
assert(hasText("43"))
faction = "Alliance"
fire("PLAYER_ENTERING_WORLD")
assert(object.text:find("PVP-Currency-Alliance", 1, true))
for i = 1, GetCurrencyListSize() do
	local _, isHeader = GetCurrencyListInfo(i)
	if not isHeader then SetCurrencyBackpack(i, 0) end
end
assert(object.text == "Click here to set up Currencies")
assert(broker.text.text == object.text)
broker:OnClick("LeftButton")
assert(openedTab == "TokenFrame")
for key, value in pairs(_G) do
	assert(hooks[key] or globalsBefore[key] == value, "Currency code changed global " .. tostring(key))
end
print("PASS: tooltip updates, folding, row movement/reuse, sizing, missing icons, tracking, and click")

-- Switch objects while hovered, exercising actual FrameSettings and Bagnon messages.
local customEnters, customLeaves = 0, 0
local customTooltip = CreateFrame("Frame", nil, UIParent)
customTooltip:Hide()
ldb:NewDataObject("Z_Custom", {
	text = "custom",
	OnEnter = function() customEnters = customEnters + 1; customTooltip:Show() end,
	OnLeave = function() customLeaves = customLeaves + 1; customTooltip:Hide() end,
})
ldb:NewDataObject("Y_Standard", {
	text = "standard",
	OnTooltipShow = function(tip) tip:SetText("standard tooltip") end,
})
broker:SetNextObject()
assert(broker:GetObjectName() == "Y_Standard")
assert(not tooltip:IsShown(), "Old custom tooltip survived plugin switch")
assert(GameTooltip:IsShown() and GameTooltip:IsOwned(broker))
broker:SetNextObject()
assert(broker:GetObjectName() == "Z_Custom")
assert(not GameTooltip:IsShown() and customTooltip:IsShown())
assert(customEnters == 1)
broker:SetPreviousObject()
assert(customLeaves == 1 and not customTooltip:IsShown())
assert(GameTooltip:IsShown())
broker:SetPreviousObject()
assert(broker:GetObjectName() == "Bagnon_Currencies" and tooltip:IsShown())
bag:Hide()
assert(not tooltip:IsShown(), "Closing the bag must dismiss its custom tooltip")
bag:Show()
broker:OnEnter()
broker:OnLeave()
assert(not tooltip:IsShown())

-- Two Bagnon windows share the currency tooltip; an old owner must not hide a new one.
local bank = bagnon.BrokerDisplay:New(1, "bank", UIParent)
broker:OnEnter()
bank:OnEnter()
broker:OnLeave()
assert(tooltip:IsShown() and tooltip.parent == bank)
bank:OnLeave()
assert(not tooltip:IsShown())
broker:OnEnter()
broker:SetObject("Missing_Plugin")
assert(not tooltip:IsShown() and not GameTooltip:IsShown())
broker:SetObject("Bagnon_Currencies")
assert(broker.text.text == object.text)
print("PASS: broker cycling, standard/custom tooltip handoff, bag close/reopen, and multiple windows")
