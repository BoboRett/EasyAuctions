EAH = {

	running = false,
	timeSinceLastUpdate = 0

}

StaticPopupDialogs["EASY_BUYOUT_AUCTION"] = {
	text = BUYOUT_AUCTION_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnCancel = function(self)
		EAH.running = false;
	end,
	hasMoneyFrame = 1,
	showAlert = 1,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
};
------------
-- Load Function
------------
function EasyAuctions_OnLoad(self)
  self.registry = {
    id = "EasyAuctions"
  }
  self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	self:RegisterEvent("UPDATE_PENDING_MAIL")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	
	
	SideDressUpFrame:SetScript("OnShow",function() EasyAuctionsFrame:SetPoint("TOPLEFT",AuctionFrame,"TOPRIGHT",180,-50) end)
	SideDressUpFrame:SetScript("OnHide",function() EasyAuctionsFrame:SetPoint("TOPLEFT",AuctionFrame,"TOPRIGHT",0,-50) end)
	
	EasyAuctionsFrame:SetScript("OnUpdate",function(self,delta)
	
			EAH.timeSinceLastUpdate = EAH.timeSinceLastUpdate + delta
			if EAH.timeSinceLastUpdate > 0.5 then
			
				EAH.timeSinceLastUpdate = 0
				EasyAuction_UpdateListings()
				
			end
			
		end
		
	)
	
  EasyAuctions_OnLoad = nil
end

------------
-- Event Functions
------------
function EasyAuctions_OnEvent(self, event, ...)

  local arg1 = ...
	
	if event == "AUCTION_HOUSE_SHOW" then
		BrowseName:SetScript("OnTextSet", function() if BrowseName:GetText() ~= "" then EasyAuction_Query() end end)
		EasyAuctionsFrame:SetParent(AuctionFrame)
		EasyAuctionsFrame:SetPoint("TOPLEFT",AuctionFrame,"TOPRIGHT",0,-50)
		EasyAuctionsFrame:Show()
	elseif event == "AUCTION_HOUSE_CLOSED" then
		BrowseName:SetScript("OnTextSet", nil)
	elseif event == "AUCTION_ITEM_LIST_UPDATE" and AuctionFrameBrowse:IsVisible() then EasyAuction_UpdateListings()
	elseif event == "UPDATE_PENDING_MAIL" then EasyAuctionsStatusText:SetText("Item bought!")
	
	end
	
end

function EasyAuction_Query()

	if not CanSendAuctionQuery() then
	
		EasyAuctionsStatusText:SetText("Waiting until able to search...")
		EasyAuctionsFrame:SetScript("OnUpdate", EasyAuction_Query)
		
		return

	else
	
		EasyAuctionsStatusText:SetText("")
		EasyAuctionsFrame:SetScript("OnUpdate", nil)
		
	end

	SortAuctionClearSort("list")
	SortAuctionSetSort("list","unitprice",false)
	
	QueryAuctionItems(BrowseName:GetText())

end

function EasyAuction_UpdateListings()

	local scrollOffset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
	local name,_,count,_,_,_,_,_,_,buyout,_,_,_,owner,_,_,itemID = GetAuctionItemInfo("list",1)
	
	if Auctionator ~= nil and name ~= nil then
		Atr_UpdateScanDBitemID(name,GetAuctionItemLink("list", 1))
		Atr_UpdateScanDBprice(name,buyout/count)
	end
	
	for i = 1, 8 do
	
		local index = i + scrollOffset+(NUM_AUCTION_ITEMS_PER_PAGE * AuctionFrameBrowse.page)
	
		local buttonName = "EAListing"..i
		local itemCount = _G[buttonName.."ItemCount"]
		local iconTexture = _G[buttonName.."ItemIconTexture"]
		local listingText = _G[buttonName.."ListingValue"]
		local buyButton = _G[buttonName.."Buy"]
		local listButton = _G[buttonName.."List"]
		local listButtonText = _G[buttonName.."ListText"]
		 
		local name,texture,count,_,_,_,_,_,_,buyout,_,_,_,owner,_,_,itemID = GetAuctionItemInfo("list",index)
		
		_G[buttonName]:SetID(index)
		
		MoneyFrame_Update(listingText,math.floor(buyout/count+0.5))
		
		iconTexture:SetTexture(texture)
		
		itemCount:SetText(count);
		itemCount:Show();
		
		if GetUnitName("player",false) == owner then
			listButton:SetText("List more")
			listButtonText:SetTextColor(0.3,0.3,1)
		else
			listButton:SetText("Undercut")
			listButtonText:SetTextColor(1,0.9,0)
		end
		
		buyButton:SetScript("onClick",function(self)
		
				if(EAH.running) then
				
					EasyAuctionsStatusText:SetText("Please wait!")
					
				else
				
					EasyAuctionsStatusText:SetText("Buying item. Please wait!")
					
					if IsShiftKeyDown() then
					
						PlaceAuctionBid("list", self:GetParent():GetID(), buyout);
					
					else
					
						EAH.running = true
						SetSelectedAuctionItem("list", self:GetParent():GetID()) 
						popup = StaticPopup_Show("EASY_BUYOUT_AUCTION")
						MoneyFrame_Update(popup.moneyFrame, buyout)
						popup.button1:SetScript("onClick", function()
								EAH.running = false
								PlaceAuctionBid("list", self:GetParent():GetID(), buyout)
								StaticPopup_Hide("EASY_BUYOUT_AUCTION")
							end
						)

					end
					
				end
				
			end
			
		)
		
		listButton:SetScript("onClick", function(self)
		
				local name,texture,count,_,_,_,_,_,_,buyout,_,_,_,owner,_,_,itemID = GetAuctionItemInfo("list",self:GetParent():GetID())
				
				AuctionFrameTab_OnClick(AuctionFrameTab3)
				
				UIDropDownMenu_Initialize(self, PriceDropDown_Initialize);
				PriceDropDown_OnClick(DropDownList1Button1)
				
				ClickAuctionSellItemButton()
				if CursorHasItem() then ClearCursor() end
				
				function findItem()
					for i = 0, 4 do

						for j = 1, GetContainerNumSlots(i) do

							if GetContainerItemID(i, j) == itemID then
							
								PickupContainerItem(i, j)
								if CursorHasItem() then ClickAuctionSellItemButton() end
								
								local undercut
								
								if GetUnitName("player",false) == owner then
									undercut = math.floor(buyout / count + 0.5)
								else
									undercut = math.floor(buyout / count - 0.5)
								end
								
								MoneyInputFrame_SetCopper(StartPrice, undercut);
								MoneyInputFrame_SetCopper(BuyoutPrice, undercut);
								
								return;
								
							end
					
						end
					
					end
				end
				
				findItem()

			end
		)
		
		 
	end

end