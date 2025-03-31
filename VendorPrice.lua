local debugMode = false
if debugMode then print("VendorPrice: Debug Mode enabled.") end

local OptionTable = {}

--/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua "accessors"
local SetTooltipTable = {
	SetBagItem = function(self, bagID, slot)
		self.hasShowedMoneyLine = true
		self.count = 0
		local info = C_Container.GetContainerItemInfo(bagID, slot)
		if info ~= nil then self.count = info.stackCount end
	end,
	SetInventoryItem = function(self, unit, slot)
		self.hasShowedMoneyLine = true
		self.count = GetInventoryItemCount(unit, slot)
	end,
	SetAuctionItem = function(self, type, index)
		self.showAsDoubleLine = true
		self.count = select(3, GetAuctionItemInfo(type, index))
	end,
	SetAuctionSellItem = function(self)
		self.showAsDoubleLine = true
		self.count = select(3, GetAuctionSellItemInfo())
	end,
	SetQuestLogItem = function(self, _, index)
		self.hasShowedMoneyLine = false
		self.count = select(3, GetQuestLogRewardInfo(index))
	end,
	SetInboxItem = function(self, index, itemIndex)
		if itemIndex then
			self.count = select(4, GetInboxItem(index, itemIndex))
		else
			self.count = select(1, select(14, GetInboxHeaderInfo(index)))
		end
	end,
	SetSendMailItem = function(self, index)
		self.count = select(4, GetSendMailItem(index))
	end,
	SetTradePlayerItem = function(self, index)
		self.count = select(3, GetTradePlayerItemInfo(index))
	end,
	SetTradeTargetItem = function(self, index)
		self.count = select(3, GetTradeTargetItemInfo(index))
	end,
	-- This is what the AH calls for items in the results
	SetItemKey = function(self, type, index)
		self.count = 1
		self.showAsDoubleLine = true
	end,
	SetItemByID = function(self, itemID)
		self.count = 1
	end,
	SetAction = function(self, itemID)
		self.hasShowedMoneyLine = true
	end,
	----[[ Still needs testing
	SetQuestItem = function(self, ...)
		local questItemType, index = ...
		self.hasShowedMoneyLine = false
		--[[
		print("SetQuestItem debug: ")
		print("GetNumQuestRewards", GetNumQuestRewards())
		print("Tooltip fields")
		for k,v in pairs(self) do
			--print(k, v)
		end
		print(select(3, GetQuestItemInfo(questItemType, index)))
		if GetNumQuestRewards() == 0 then return end
		--]]
		self.count = select(3, GetQuestItemInfo(questItemType, index))
	end,
	--]]
	--[[ Testing functions
	SetTradeSkillItem = function(self, type, index)
		print("SetTradeSkillItem")
	end,
	]]
}

local debugColors = {"ff", "00", "00"}

local function showTooltipFunction(tooltip, functionName)
	if debugMode then
		local color = "ff"..debugColors[1] .. debugColors[2] .. debugColors[3]
		table.insert(debugColors, table.remove(debugColors, 1))

		local name, link = tooltip:GetItem()
		tooltip.time = GetTime()

		print(tooltip:GetName())
		print("|c"..color..functionName.."|r", tooltip.time)
		print("-> name/link", name, link)
		print("-> count", tooltip.count)
		print("-> hasShowedMoneyLine", tooltip.hasShowedMoneyLine)
		print("-> hasMoney", tooltip.hasMoney)
		print("-> showAsDoubleLine", tooltip.showAsDoubleLine)
		for k,v in pairs(tooltip) do
			--print(k)
		end
		if tooltip and tooltip.GetRowData then
			local data = tooltip:GetRowData()
			print(DevTools_Dump(data))
		end
	end
end

for functionName, hookfunc in pairs (SetTooltipTable) do
	hooksecurefunc(GameTooltip, functionName, hookfunc)
	hooksecurefunc(GameTooltip, functionName, function(self) showTooltipFunction(self, functionName) end)
end

local OnTooltipSetItem = function(self, ...)
	-- immediately return if the player is interacting with a vendor
	if debugMode then
		print("Starting OnTooltipSetItem", self.time)
		print(self.count, self.hasShowedMoneyLine)
	end
	if MerchantFrame:IsShown() then return end
	if self.vendorPriceTooltipShown then
		if debugMode then print("Exit: vendorPriceTooltipShown", self.vendorPriceTooltipShown) end
		return
	end

	self.vendorPriceTooltipShown = true

	local name, link = self:GetItem()
	if debugMode and self.count then print ("".. name .." (".. self.count ..")", self.hasShowedMoneyLine) end
	if not link then return end

	--local class = select(6, GetItemInfo(link))
	local vendorPrice = select(11, GetItemInfo(link))
	if not vendorPrice then return end
	self.hasShowedMoneyLine = self.hasShowedMoneyLine or false
	if vendorPrice == 0 then
		self:AddLine(NO_SELL_PRICE_TEXT, 1, 1, 1)
	else
		if not self.hasShowedMoneyLine then
			if debugMode then print("Show money line") end
			self.count = self.count or 1
			if self.showAsDoubleLine then
				self:AddDoubleLine("Sell Price:", C_CurrencyInfo.GetCoinTextureString(vendorPrice * self.count, 14), 1,1,1, 1,1,1)
			else
				self:AddLine("Sell Price:    "..C_CurrencyInfo.GetCoinTextureString(vendorPrice * self.count, 14), 1, 1, 1)
			end
		end
	end
	self.count = nil
	self.hasShowedMoneyLine = nil
	self.showAsDoubleLine = nil
end

local OnTooltipCleared = function (self, ...)
	--self.hasShowedMoneyLine = nil
	self.vendorPriceTooltipShown = false
	if debugMode then print("Cleared", self.time) end
end

for _, Tooltip in pairs {GameTooltip, ItemRefTooltip} do
--for _, Tooltip in pairs {GameTooltip} do
	Tooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	Tooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
end

