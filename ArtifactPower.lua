local tooltipScanner
local tooltipName = "ArtifactPowerTooltipScanner"
local bagPower,currentPower,worldQuestPower,worldQuestPowerLooseSoon,powerNextLevel;
local f  = CreateFrame("frame",nil,UIParent);
local numberOverlay = {};
local ldb =  LibStub:GetLibrary("LibDataBroker-1.1");
local ldbPower;
local brokenIslesZones = {};
local addonName,ns = ...
local EMPOWERING_SPELL_ID = 227907
local empoweringSpellName
local totalApRanks = 54
local totalApRanksPurchased = 0;
local apStats = {}
local addonActive = false;
local secure_buttons = {}
local secure_button_count=0;
local lwin = LibStub("LibWindow-1.1")
local powerItemsInBag = {}
local bankOpen = false;
local apString = {
	  ["enUS"] = "Grants (%d+) Artifact Power to your currently equipped Artifact",
	 ["enGB"] = "Grants (%d+) Artifact Power to your currently equipped Artifact",
	 ["ptBR"] = "Concede (%d+) de Poder do Artefato ao artefato equipado",
	 ["esMX"] = "Otorga (%d+) p de Poder de artefacto para el artefacto que llevas equipado",
	 ["deDE"] = "Gewährt Eurem derzeit ausgerüsteten Artefakt (%d+) Artefaktmacht",
	 ["esES"] = "Otorga (%d+) p de poder de artefacto al artefacto que lleves equipado",
	 ["frFR"] = "Confère (%d+) points de puissance à l’arme prodigieuse que vous maniez",
	 ["itIT"] = "Fornisce (%d+) Potere Artefatto all'Artefatto attualmente equipaggiato",
	 ["plPL"] = "Grants (%d+) Artifact Power to your currently equipped Artifact",
	 ["ptPT"] = "Concede (%d+) de Poder do Artefato ao artefato equipado",
	 ["ruRU"] = "Добавляет используемому в данный момент артефакту (%d+) ед силы артефакта",
	 ["koKR"] = "현재 장착한 유물에 (%d+)의 유물력을 부여합니다",
	 ["zhTW"] = "賦予你目前裝備的神兵武器(%d+)點神兵之力。",
}
local apStringLocal = apString[GetLocale()]
function f:OnLoad()
	empoweringSpellName = GetSpellInfo(EMPOWERING_SPELL_ID)
	f:SetScript("OnEvent",f.EventHandler);	
	f:RegisterEvent("BAG_UPDATE_DELAYED");	
	f:RegisterEvent("ADDON_LOADED");
	f:RegisterEvent("ARTIFACT_UPDATE")
	f:RegisterEvent("BANKFRAME_OPENED")
	f:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	f:RegisterEvent("BANKFRAME_CLOSED")
	f:RegisterEvent("QUEST_LOG_UPDATE");

	
	tooltipScanner = CreateFrame("GameTooltip", tooltipName, nil, "GameTooltipTemplate")
	ldbPower = ldb:NewDataObject("Artifact Power", { type = "data source", label ="Artifact Power", text = "", icon = "Interface\\ICONS\\INV_Artifact_XP05",OnTooltipShow = function (self) self:AddLine("Left click to show/hide the Artifact Power Button Bar |nRight click to open the config") end, OnClick = f.DataBrokerClick});
	brokenIslesZones =  { GetMapZones(8) } ;
end


function f:DataBrokerClick(mouseButton)
	if(mouseButton  == "RightButton") then
	InterfaceOptionsFrame_OpenToCategory(ns.configFrame)
	InterfaceOptionsFrame_OpenToCategory(ns.configFrame)
	
	elseif(mouseButton == "LeftButton" and apStats.bagPower > 0) then
		if(secure_buttons[1]:IsVisible() == true) then
			
			f:HideSecureButtons()
		else
			
			f:ShowButtonBar();
			
		end
	end

end

function f:ShowButtonBar()
	--CreateUseButton
	secure_button_count = 0
	local itemID,count,curBagPower
	for itemID,curBagPower in pairs(powerItemsInBag) do	
			f:CreateUseButton(itemID,curBagPower.count,curBagPower.totalGain);
	end

end

function f:CheckBags()	
	
	f:GetArtifactInfos()
	f:ScanWorldQuests();
	apStats.bagPower = 0;
	powerItemsInBag = {};
	
	local itemLink,powerGain,rawPowerGain,itemID,itemCount;
	for bag = 0, 4 do	
		for slot = 1, GetContainerNumSlots(bag) do
			itemLink = GetContainerItemLink(bag, slot)
			powerGain = f:GetItemLinkArtifactPower(itemLink,1);
			if(powerGain~=nil) then
				apStats.bagPower = apStats.bagPower + powerGain	
				_, count, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(bag, slot)
				if not powerItemsInBag[itemID] then
					powerItemsInBag[itemID] = {}
					powerItemsInBag[itemID].count = count
					powerItemsInBag[itemID].totalGain = powerGain
				else
					powerItemsInBag[itemID].count = powerItemsInBag[itemID].count + count
					powerItemsInBag[itemID].totalGain = powerItemsInBag[itemID].totalGain + powerGain
				end
			end
		end
	end
	if bankOpen == true then
		f:ScanBank()
	end
	apStats.bagPower = apStats.bagPower + ArtifactPowerBank
	if(secure_buttons[1]:IsVisible() == true) then
		f:HideSecureButtons()
		f:ShowButtonBar()
	end
	if apStats.powerNextLevel ~= nil then
		apStats.powerNextLevelLeft = apStats.powerNextLevel - apStats.bagPower - apStats.currentPower
	end
end

function f:HideSecureButtons()
	if(secure_buttons) then
			for _,btn in pairs(secure_buttons) do
				btn:Hide();
			end
			
	end
	

end

function f:CreateSecureButttons(i)
		--for i=1,15 do
			secure_buttons[i] = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate,ActionButtonTemplate");
			local btn = secure_buttons[i];
			btn:SetWidth(40);
			btn:SetHeight(40);
			btn.counter = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal");
			btn.counter:SetPoint("BOTTOMRIGHT", btn);
			btn.totalGain = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal");
			btn.totalGain:SetPoint("TOPLEFT", btn);
			if(i==1) then
				--btn:SetPoint("Center",UIParent)
				btn:SetMovable(true);
				lwin.RegisterConfig(btn, ns.config.frame_secure_pos)
				lwin.RestorePosition(btn)  -- restores scale also
				btn:RegisterForDrag("LeftButton");
				
				btn:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
				btn:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); lwin.SavePosition(self); end);
			end
			if (i>1 and (i-1) % 8 == 0) then
				btn:SetPoint("BOTTOM",secure_buttons[i-8],0,-40);
					
			elseif i > 1 then
				btn:SetPoint("RIGHT",secure_buttons[i-1],40,0);
			
			end
			
		
			btn:Hide();	
		--end
end

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function f:FormatTotalGain(gain)
	if gain < 1000 then
		return gain
	elseif gain < 1000000 then
		return round(gain / 1000,3).."k"
	else
		return round (gain / 1000000,3).."m"
	end
end

function f:CreateUseButton(itemid,itemcount,totalGain)		
		secure_button_count=secure_button_count+1;
		if(secure_buttons[secure_button_count]==nil) then
			f:CreateSecureButttons(secure_button_count)
		end
		local btn = secure_buttons[secure_button_count];
				
		btn.itemid = itemid;
		btn:SetAttribute("type1", "item");
		btn:SetAttribute("item1", "item:"..itemid);
		
		btn.icon:SetTexture(GetItemIcon(itemid));
		btn.icon:SetAllPoints(true);
		btn:SetWidth(40);
		btn.counter:SetText(itemcount);
		btn.totalGain:SetText(f:FormatTotalGain(totalGain));
		--btn.counter:SetText(secure_button_count);
		--btn:SetScript("OnEnter", function(self) GameTooltip:SetItemByID(itemid);GameTooltip:Show() end)
		--btn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		
		btn:Show();
	
	
end


function f:ScanBank()
		local itemLink	
		ns.bankPower = 0
		for num = 1, NUM_BANKGENERIC_SLOTS do
			local _, _, _, _, _, _, itemLink = GetContainerItemInfo(BANK_CONTAINER, num)
			if itemLink then
				
				powerGain = f:GetItemLinkArtifactPower(itemLink);
				if(powerGain~=nil) then
					ns.bankPower = ns.bankPower + powerGain						
					
				end
			end
		end

	
		for bagNum = ITEM_INVENTORY_BANK_BAG_OFFSET+1, ITEM_INVENTORY_BANK_BAG_OFFSET+NUM_BANKBAGSLOTS do
			local bagNum_ID = BankButtonIDToInvSlotID(bagNum, 1)-4		
			local bagItemLink = GetInventoryItemLink("player", bagNum_ID)
			if bagItemLink then		
				
				for bagItem = 1, GetContainerNumSlots(bagNum) do
					local _, _, _, _, _, _, itemLink = GetContainerItemInfo(bagNum, bagItem)
					if itemLink then
						
						powerGain = f:GetItemLinkArtifactPower(itemLink);
						if(powerGain~=nil) then
							
						
							ns.bankPower = ns.bankPower + powerGain						
						end
					end
				end			
			end
		end
	
	ArtifactPowerBank = ns.bankPower
end

function f:EventHandler(event,...)
	if(event=="BAG_UPDATE_DELAYED") then
		f:CheckBags();
		f:GetArtifactInfos();
		f:ShowText();
	
	elseif(event=="BANKFRAME_OPENED" or event == "PLAYERBANKSLOTS_CHANGED") then
		f:ScanBank();
		bankOpen = true
	elseif(event=="BANKFRAME_CLOSED") then
		bankOpen = false
	elseif(event == "ADDON_LOADED") then
		local addonLoaded = ...;
		if (addonName == addonLoaded) then
			
			f:UnregisterEvent("ADDON_LOADED");
			ns.configFrame:Init();
			f:CreateSecureButttons(1)
			if ArtifactPowerBank == nil then ArtifactPowerBank = 0 end
			ns.bankPower = ArtifactPowerBank;
			addonActive = true;
			
		end
	elseif(event=="QUEST_LOG_UPDATE") then
			
			if WorldMapFrame:IsShown() then
				return
			end
			f:CheckBags();
			f:GetArtifactInfos();
			f:ShowText();
			
	elseif(event=="ARTIFACT_UPDATE") then
		local arg1 = ...;
		if(arg1==true) then
			f:GetTotalRanks();
		end
	end

end

function f:ScanWorldQuests()

	local index,value,worldQuests,timeLeft,i,itemLink,ap,itemID,worldQuestType,exclude,_;
	apStats.worldQuestPower = 0;
	apStats.worldQuestPowerLooseSoon = 0;
	local oldmapid = GetCurrentMapAreaID();
	local oldlevel = GetCurrentMapDungeonLevel();
	for index,value in pairs(brokenIslesZones) do			
		if tonumber(value) ~= nil then
			SetMapByID(value)
			worldQuests = C_TaskQuest.GetQuestsForPlayerByMapID(value)
			if worldQuests then					
				for i = 1, #worldQuests do
					exclude = false
					
						_, _, worldQuestType = GetQuestTagInfo(worldQuests[i].questId);
						
						if ns.config.ExcludeList[worldQuestType] ~= nil and ns.config.ExcludeList[worldQuestType] == true then
							exclude = true
						end
					
					timeLeft = C_TaskQuest.GetQuestTimeLeftMinutes(worldQuests[i].questId)
					if timeLeft > 0 and exclude == false then
						questId = worldQuests[i].questId
						if GetNumQuestLogRewards(questId) > 0 then
							_, _, _, _, _, itemID = GetQuestLogRewardInfo (1, questId)
							if(itemID) then
								_,itemLink = GetItemInfo(itemID);
								ap = f:GetItemLinkArtifactPower(itemLink);
								if(ap~=nil) then
									if(timeLeft>60) then
										apStats.worldQuestPower = apStats.worldQuestPower + ap;
									else
										apStats.worldQuestPowerLooseSoon = apStats.worldQuestPowerLooseSoon + ap;
									end
								end
							end
						end
					end
					
				end
			end
		end
	end
	SetMapByID(oldmapid);
	SetDungeonMapLevel(oldlevel);
end

local function RGBPercToHex(r, g, b, a)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	a = a <= 1 and a >= 0 and a or 0
	return string.format("%02x%02x%02x%02x",a*255, r*255, g*255, b*255)
end

function f:ReplaceTags(tag)
	if(apStats[tag] == nil) then return 0 end
	return "|c"..RGBPercToHex(ns.config["color"..tag][1],ns.config["color"..tag][2],ns.config["color"..tag][3],ns.config["color"..tag][4])..(apStats[tag] or 0).."|r"
	--return tag
end

function f:ShowText()
	local text;
	if(addonActive==false) then return end
	--print("goingtext")
	--local text = "#currentPower#"
	text = ns.config.DisplayString:gsub("#(.-)#", function(a) return f:ReplaceTags(a) end)
	ldbPower.text = text;
	--ldbPower.text = "(|c00FFFFFF"..(currentPower or 0).."|r/|c0000FF00"..bagPower.."|r/|c00FFFF00"..worldQuestPower.."|r/|c00FF8C00"..worldQuestPowerLooseSoon.."|r/"..(powerNextLevel or 0)..")";
end

function f:GetTotalRanks()
	totalApRanksPurchased = C_ArtifactUI.GetTotalPurchasedRanks()
	local totalCost = 0
	local lastTotalCost = 0
	for i=1,totalApRanks do
		totalCost = totalCost + C_ArtifactUI.GetCostForPointAtRank(i);
		if(lastTotalCost>0) then
			local percent = totalCost / lastTotalCost 			
		end
		lastTotalCost = totalCost
	end
	--print (totalCost)
	
end

function f:GetArtifactInfos()	
	
	local itemID, altItemID, name, icon, totalXP, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo();
	 if(pointsSpent == nil) then return; end
	local numPointsAvailableToSpend, xp , xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP);

	apStats.currentPower = xp;
	apStats.powerNextLevel = xpForNextPoint;
	
	

end

function f:GetItemLinkArtifactPower(itemLink, baggy)
    if itemLink then
        local itemSpell = GetItemSpell(itemLink)
        if itemSpell and itemSpell == empoweringSpellName then
            tooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
            tooltipScanner:SetHyperlink (itemLink)
			local i
			--if baggy ~= nil then
				--print ("ap item found")
			--end
			for i=tooltipScanner:NumLines(),1,-1 do
			
				local tooltipText = _G[tooltipName.."TextLeft"..i]:GetText()
				--if baggy ~= nil then
				--	print (tooltipText)
				--end
				if(tooltipText ~= nil) then
					 local ap = tooltipText:gsub("[,%.]", ""):match(apStringLocal) or ""
					if ap ~= "" then
						tooltipScanner:Hide()			
						return tonumber(ap);
					end
					
				end
			--matcher = "Grants (%d+) Artifact Power to your currently equipped Artifact"
           end
        else
            return nil
        end
    else
        return nil
    end

end




f:OnLoad();
