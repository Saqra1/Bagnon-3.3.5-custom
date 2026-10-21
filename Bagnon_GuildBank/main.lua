--[[
	main.lua
		The bagnon driver thingy
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local GuildBank = Bagnon:NewModule('GuildBank', 'AceEvent-3.0')

function GuildBank:OnEnable()
	Bagnon.GuildFrame:New('guildbank')

	self:RegisterEvent('GUILDBANKFRAME_OPENED')
	self:RegisterEvent('GUILDBANKFRAME_CLOSED')
	self:RegisterEvent('GUILDBANK_UPDATE_TABS', 'UpdateCurrentTab')
	self:RegisterEvent('GUILD_ROSTER_UPDATE', 'UpdateCurrentTab')
end

function GuildBank:GUILDBANKFRAME_OPENED()
	if self.atBank then return end
	self.atBank = true
	self:UpdateCurrentTab()
	Bagnon.FrameSettings:Get('guildbank'):Show()
end

function GuildBank:GUILDBANKFRAME_CLOSED()
	self.atBank = nil
	self.selectedTab = nil
	Bagnon.FrameSettings:Get('guildbank'):Hide()
end

function GuildBank:IsTabViewable(tab)
	if self.atBank and tab and tab >= 1 and tab <= GetNumGuildBankTabs() then
		return not not select(3, GetGuildBankTabInfo(tab))
	end
	return false
end

function GuildBank:GetCurrentTab()
	local tab = GetCurrentGuildBankTab()
	if self:IsTabViewable(tab) then
		return tab
	end
end

function GuildBank:SelectTab(tab)
	if not self:IsTabViewable(tab) then return false end

	SetCurrentGuildBankTab(tab)
	self.selectedTab = tab
	Bagnon.Callbacks:SendMessage('GUILD_BANK_TAB_CHANGE', tab)
	QueryGuildBankTab(tab)
	return true
end

function GuildBank:UpdateCurrentTab()
	if not self.atBank then return end

	local tab = self:GetCurrentTab()
	if not tab then
		for id = 1, GetNumGuildBankTabs() do
			if self:IsTabViewable(id) then
				tab = id
				break
			end
		end
	end

	if tab and tab ~= self.selectedTab then
		self:SelectTab(tab)
	else
		self.selectedTab = tab
		Bagnon.Callbacks:SendMessage('GUILD_BANK_TAB_CHANGE', tab)
	end
end
