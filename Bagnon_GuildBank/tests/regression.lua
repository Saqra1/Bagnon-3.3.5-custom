-- Run from Interface/AddOns: lua Bagnon_GuildBank/tests/regression.lua
-- Optional first argument: a different Bagnon_GuildBank directory to check.
local addonDir = arg[1] or 'Bagnon_GuildBank'
local frames, methods = {}, {}
local currentTab, numTabs = 1, 0
local tabs = {
	{viewable = false, remaining = 0},
	{viewable = true, remaining = 7},
	{viewable = true, remaining = 4},
	{viewable = true, remaining = 2},
}
local cache, queries, pickups = {}, {}, {}
local cursorMoney, deposited, dropped = 0, nil, 0
local columns = 14

local function compileLua(path)
	local file = assert(io.open(path, 'rb'))
	local source = file:read('*a'):gsub('^\239\187\191', '')
	file:close()
	return assert(loadstring(source, '@' .. path))
end

local function equal(actual, expected, message)
	assert(actual == expected, message .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end

function methods:IsShown() return self._shown end
function methods:IsVisible()
	return self._shown and (not self._parent or self._parent:IsVisible())
end
local function visibility(frame, shown)
	local previous = {}
	for _, child in ipairs(frames) do previous[child] = child:IsVisible() end
	frame._shown = shown
	for _, child in ipairs(frames) do
		local visible = child:IsVisible()
		if visible ~= previous[child] then
			local handler = child._scripts[visible and 'OnShow' or 'OnHide']
			if handler then handler(child) end
		end
	end
end
function methods:Show() visibility(self, true) end
function methods:Hide() visibility(self, false) end
function methods:SetParent(parent) self._parent = parent end
function methods:GetParent() return self._parent end
function methods:SetID(id) self._id = id end
function methods:GetID() return self._id end
function methods:GetName() return self._name end
function methods:SetWidth(width) self._width = width end
function methods:SetHeight(height) self._height = height end
function methods:GetWidth() return self._width end
function methods:GetHeight() return self._height end
function methods:SetPoint(...) self._point = {...} end
function methods:ClearAllPoints() self._point = nil end
function methods:SetScript(event, handler) self._scripts[event] = handler end
function methods:RegisterEvent(event) self._events[event] = true end
function methods:UnregisterAllEvents() self._events = {} end
function methods:Enable() self._enabled = true end
function methods:Disable() self._enabled = false end
function methods:SetChecked(checked) self._checked = not not checked end
function methods:SetText(text) self._text = text end
function methods:SetFormattedText(format, ...) self._text = string.format(format, ...) end
function methods:SetTexture(texture) self._texture = texture end
function methods:GetFrameLevel() return 1 end
function methods:GetRight() return 100 end
for _, name in ipairs({'SetAllPoints', 'RegisterForClicks', 'RegisterForDrag', 'SetNormalTexture',
	'SetPushedTexture', 'SetHighlightTexture', 'SetCheckedTexture', 'SetFontObject', 'SetJustifyH',
	'SetBlendMode', 'SetVertexColor', 'SetAlpha', 'SetFrameLevel'}) do
	methods[name] = function() end
end
function CreateFrame(kind, name, parent)
	local frame = {_name = name, _parent = parent, _shown = true, _enabled = true,
		_width = 0, _height = 0, _scripts = {}, _events = {}}
	for key, method in pairs(methods) do frame[key] = method end
	frames[#frames + 1] = frame
	if name then _G[name] = frame end
	return frame
end
function methods:CreateTexture(name) return CreateFrame('Texture', name, self) end
function methods:CreateFontString(name) return CreateFrame('FontString', name, self) end
local function fire(event, ...)
	local listeners = {}
	for _, frame in ipairs(frames) do
		if frame._events[event] then listeners[#listeners + 1] = frame end
	end
	for _, frame in ipairs(listeners) do
		if frame._events[event] and frame._scripts.OnEvent then frame._scripts.OnEvent(frame, event, ...) end
	end
end

MAX_GUILDBANK_TABS = 6
UIParent = CreateFrame('Frame')
GameTooltip = {IsOwned = function(self, owner) return self.owner == owner end,
	SetOwner = function(self, owner) self.owner = owner end,
	SetGuildBankItem = function(self, tab, slot) self.tab, self.slot = tab, slot end,
	Show = function() end, Hide = function(self) self.owner = nil end}
StackSplitFrame = {Hide = function(self) self.hidden = true end}
function GetScreenWidth() return 1024 end
function GetAuctionItemClasses() return unpack({'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', 'Quest'}) end
function GetNumGuildBankTabs() return numTabs end
function GetCurrentGuildBankTab() return currentTab end
function GetGuildBankTabInfo(tab)
	if tab < 1 or tab > numTabs then return end
	local info = tabs[tab]
	return 'Tab ' .. tab, 'icon' .. tab, info.viewable, true, 10, info.remaining
end
function SetCurrentGuildBankTab(tab)
	assert(tab >= 1 and tab <= numTabs and tabs[tab].viewable, 'selected an unavailable tab')
	currentTab = tab
end
function QueryGuildBankTab(tab)
	assert(tab >= 1 and tab <= numTabs and tabs[tab].viewable, 'requested an unavailable tab')
	queries[#queries + 1] = tab
end
function GetGuildBankItemInfo(tab, slot)
	if tab < 1 or tab > numTabs or not tabs[tab].viewable then return end
	local item = cache[tab] and cache[tab][slot]
	return item and 'texture-' .. item, item and 5 or 0, nil
end
function GetGuildBankItemLink(tab, slot) return cache[tab] and cache[tab][slot] end
local function reply(tab)
	cache[tab] = {[1] = 'item-' .. tab}
	fire('GUILDBANKBAGSLOTS_CHANGED')
end
function SetItemButtonTexture(button, texture) button._texture = texture end
function SetItemButtonCount(button, count) button._count = count end
function SetItemButtonDesaturated() end
function SetItemButtonTextureVertexColor() end
function GetItemInfo(link) return link, link, 1 end
function HandleModifiedItemClick() return false end
function IsModifiedClick() return false end
function GetCursorInfo() return nil end
function PickupGuildBankItem(tab, slot) pickups[#pickups + 1] = {tab, slot} end
function GetCursorMoney() return cursorMoney end
function DepositGuildBankMoney(amount) deposited = amount end
function DropCursorMoney() dropped = dropped + 1; cursorMoney = 0 end
function GetGuildBankMoney() return 0 end
function MoneyFrame_Update() end

local bagnon, guildBank, root = {Settings = {}, FrameSettings = {}}, nil, nil
function bagnon:NewModule()
	guildBank = {}
	local eventFrame = CreateFrame('Frame')
	function guildBank:RegisterEvent(event, method)
		eventFrame:RegisterEvent(event)
		eventFrame[event] = method or event
	end
	eventFrame:SetScript('OnEvent', function(self, event, ...) guildBank[self[event]](guildBank, event, ...) end)
	return guildBank
end
function bagnon:GetModule() return guildBank end
function bagnon.Settings:GetTextSearch() return '' end
function bagnon.Settings:HighlightingItemsByQuality() return false end
function bagnon.Settings:HighlightingQuestItems() return false end
function bagnon.Settings:ShowingEmptyItemSlotTextures() return true end
local settings = {}
function settings:GetItemFrameColumns() return columns end
function settings:GetItemFrameSpacing() return 2 end
function settings:Show() root:Show() end
function settings:Hide() root:Hide() end
function bagnon.FrameSettings:Get() return settings end
local addonLibrary = {GetAddon = function() return bagnon end}
function LibStub(name)
	if name == 'AceAddon-3.0' then return addonLibrary end
	if name == 'LibItemSearch-1.0' then return {Find = function() return false end} end
	if name == 'AceLocale-3.0' then return {GetLocale = function() return {} end} end
	error('unexpected library: ' .. name)
end

compileLua('Bagnon/utility/ears.lua')()
compileLua('Bagnon/utility/callbacks.lua')()
compileLua('Bagnon/utility/classy.lua')()
for _, file in ipairs({'main.lua', 'components/item.lua', 'components/itemFrame.lua',
	'components/tab.lua', 'components/tabFrame.lua', 'components/moneyFrame.lua'}) do
	compileLua(addonDir .. '/' .. file)()
end
-- Check syntax of the remaining files without replacing the real parent frame UI.
compileLua(addonDir .. '/components/frame.lua')
compileLua(addonDir .. '/components/savedFrameSettings.lua')
bagnon.GuildFrame = {New = function()
	root = CreateFrame('Frame', nil, UIParent)
	root:Hide()
	root.items = bagnon.GuildItemFrame:New('guildbank', root)
	root.tabs = bagnon.GuildTabFrame:New('guildbank', root)
	root.tabs:Show()
	return root
end}
guildBank:OnEnable()

fire('GUILDBANKFRAME_OPENED')
equal(#queries, 0, 'opening before tab metadata does not query an invalid tab')
equal(#root.items.itemSlots, 0, 'opening before tab metadata has an empty grid')
numTabs = 3
fire('GUILDBANK_UPDATE_TABS')
equal(currentTab, 2, 'opening selects the first accessible tab')
equal(queries[#queries], 2, 'opening queries the accessible tab')
equal(#root.items.itemSlots, 98, 'accessible tab has 98 slots')
equal(root.tabs.bags[1]._enabled, false, 'inaccessible tab is disabled')
equal(root.tabs.bags[4]:IsShown(), false, 'unpurchased tab is hidden')
reply(2)
equal(root.items.itemSlots[1]:GetItem(), 'item-2', 'server reply populates items')
root.items.itemSlots[1].hasStackSplit = 1
StackSplitFrame.hidden = false

root.tabs.bags[3]:OnClick()
equal(currentTab, 3, 'click selects the new tab')
equal(root.items.itemSlots[1].tab, 3, 'slot target changes before server reply')
equal(root.items.itemSlots[1]:GetItem(), nil, 'previous tab item disappears immediately')
equal(StackSplitFrame.hidden, true, 'switching tabs closes the old stack split')
equal(root.tabs.bags[2]._checked, false, 'old tab is unchecked')
equal(root.tabs.bags[3]._checked, true, 'new tab is checked')
root.items.itemSlots[1]:OnClick('LeftButton')
equal(pickups[#pickups][1], 3, 'pending-query clicks target the selected tab')
root.items.itemSlots[1]:OnEnter()
equal(GameTooltip.tab, 3, 'tooltip targets the selected tab')
reply(3)
reply(2)
equal(root.items.itemSlots[1]:GetItem(), 'item-3', 'late reply cannot restore the old tab')
root.tabs.bags[2]:OnClick()
equal(root.items.itemSlots[1]:GetItem(), 'item-2', 'cached tab contents appear immediately')

local queryCount = #queries
root.tabs.bags[1]:OnClick()
root.tabs.bags[4]:OnClick()
equal(#queries, queryCount, 'unavailable tab clicks do not query')
for _ = 1, 3 do fire('GUILDBANK_UPDATE_TABS'); fire('GUILD_ROSTER_UPDATE') end
equal(#queries, queryCount, 'metadata updates do not create query loops')
tabs[2].viewable = false
fire('GUILD_ROSTER_UPDATE')
equal(currentTab, 3, 'permission loss selects an accessible replacement')
equal(root.items.itemSlots[1].tab, 3, 'permission fallback retargets the grid')
equal(root.tabs.bags[2]._enabled, false, 'permission loss disables the old tab')
tabs[3].viewable = false
fire('GUILDBANK_UPDATE_TABS')
equal(#root.items.itemSlots, 0, 'no accessible tabs clears the grid')
equal(GameTooltip.owner, nil, 'removing hovered slots hides their tooltip')
root.items:Layout()
equal(root.items:GetWidth(), 1, 'empty grid has a valid width')
equal(root.items:GetHeight(), 1, 'empty grid has a valid height')

tabs[1].viewable = true
fire('GUILDBANK_UPDATE_TABS')
equal(currentTab, 1, 'new access selects a valid tab')
equal(#root.items.itemSlots, 98, 'new access restores the grid')
reply(1)
for value = 4, 36 do
	columns = value
	root.items:Layout()
	local positions = {}
	for _, slot in ipairs(root.items.itemSlots) do
		local x, y = slot._point[4], slot._point[5]
		assert(x + 39 <= root.items:GetWidth(), 'slot exceeds grid width')
		assert(-y + 39 <= root.items:GetHeight(), 'slot exceeds grid height')
		local key = x .. ':' .. y
		assert(not positions[key], 'item slots overlap')
		positions[key] = true
	end
	assert(root.items:GetWidth() <= 41 * columns - 2, 'layout exceeds configured columns')
end
numTabs = 4
fire('GUILDBANK_UPDATE_TABS')
equal(root.tabs.bags[4]:IsShown(), true, 'newly purchased tab becomes visible')
equal(root.tabs.bags[4]._enabled, true, 'newly purchased tab is enabled')
numTabs = 0
fire('GUILDBANK_UPDATE_TABS')
equal(#root.items.itemSlots, 0, 'zero purchased tabs clears the grid')
for _, tab in ipairs(root.tabs.bags) do equal(tab:IsShown(), false, 'zero purchased tabs hides buttons') end
assert(root.tabs:GetWidth() > 0, 'empty tab bar has a valid width')

fire('GUILDBANKFRAME_CLOSED')
queryCount = #queries
fire('GUILDBANK_UPDATE_TABS')
fire('GUILD_ROSTER_UPDATE')
equal(#queries, queryCount, 'closed bank ignores metadata queries')
equal(guildBank:SelectTab(1), false, 'closed bank rejects tab selection')
numTabs = 3
fire('GUILDBANKFRAME_OPENED')
equal(#queries, queryCount + 1, 'reopening requests fresh contents')
fire('GUILDBANKFRAME_OPENED')
equal(#queries, queryCount + 1, 'duplicate open does not add queries')

local moneyFrame = bagnon.GuildMoneyFrame:New('guildbank', root)
cursorMoney = 123456
moneyFrame:OnClick('LeftButton')
equal(deposited, 123456, 'cursor deposit passes the exact copper amount')
equal(dropped, 1, 'cursor money is released after depositing')
print('PASS: opening, tab switches, delayed replies, permissions, purchases, empty banks, layouts, reopening, and money deposits')
