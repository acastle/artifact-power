local tooltipScanner
local tooltipName = "ArtifactPowerTooltipScanner"
local totalPower,currentPower,worldQuestPower,worldQuestPowerLooseSoon,powerNextLevel;
local f  = CreateFrame("frame",nil,UIParent);
local numberOverlay = {};
local ldb =  LibStub:GetLibrary("LibDataBroker-1.1");
local ldbPower;
local brokenIslesZones = {};
local addonName,ns = ...
local EMPOWERING_SPELL_ID = 227907
local empoweringSpellName

function f:OnLoad()
	empoweringSpellName = GetSpellInfo(EMPOWERING_SPELL_ID)
	f:SetScript("OnEvent",f.EventHandler);	
	f:RegisterEvent("BAG_UPDATE_DELAYED");	
	f:RegisterEvent("ADDON_LOADED");
	tooltipScanner = CreateFrame("GameTooltip", tooltipName, nil, "GameTooltipTemplate")
	ldbPower = ldb:NewDataObject("Artifact Power", { type = "data source", label ="", text = "", icon = "Interface\\ICONS\\INV_Artifact_XP05"});
	brokenIslesZones =  { GetMapZones(8) } ;
end


function f:CheckBags()	
	f:GetArtifactInfos()
	f:ScanWorldQuests();
	totalPower = 0;
	local itemLink,powerGain,rawPowerGain;
	for bag = 0, 4 do	
		for slot = 1, GetContainerNumSlots(bag) do
			itemLink = GetContainerItemLink(bag, slot)
			powerGain = f:GetItemLinkArtifactPower(itemLink);
			if(powerGain~=nil) then
				totalPower = totalPower + powerGain	
			
			end
		end
	end
	
	
end

function f:EventHandler(event,...)
	if(event=="BAG_UPDATE_DELAYED") then
		f:CheckBags();
		f:GetArtifactInfos();
		f:ShowText();
	elseif(event == "ADDON_LOADED") then
		local addonLoaded = ...;
		if (addonName == addonLoaded) then
			
			f:UnregisterEvent("ADDON_LOADED");
			ns.configFrame:Init();
		end
	end

end

function f:ScanWorldQuests()
	local index,value,worldQuests,timeLeft,i,itemLink,ap,itemID,worldQuestType,isPvP,_;
	worldQuestPower = 0;
	worldQuestPowerLooseSoon = 0;
	for index,value in pairs(brokenIslesZones) do			
		if tonumber(value) ~= nil then
			SetMapByID(value)
			worldQuests = C_TaskQuest.GetQuestsForPlayerByMapID(value)
			if worldQuests then					
				for i = 1, #worldQuests do
					isPvP = false
					if ns.config["IncludePvP"] == false then
						_, _, worldQuestType = GetQuestTagInfo(worldQuests[i].questId);
						if worldQuestType == 4 then
							isPvP = true
						end
					end
					timeLeft = C_TaskQuest.GetQuestTimeLeftMinutes(worldQuests[i].questId)
					if timeLeft > 0 and isPvP == false then
						questId = worldQuests[i].questId
						if GetNumQuestLogRewards(questId) > 0 then
							_, _, _, _, _, itemID = GetQuestLogRewardInfo (1, questId)
							if(itemID) then
								_,itemLink = GetItemInfo(itemID);
								ap = f:GetItemLinkArtifactPower(itemLink);
								if(ap~=nil) then
									if(timeLeft>60) then
										worldQuestPower = worldQuestPower + ap;
									else
										worldQuestPowerLooseSoon = worldQuestPowerLooseSoon + ap;
									end
								end
							end
						end
					end
					
				end
			end
		end
	end
end

function f:ShowText()
	ldbPower.text = "(|c00FFFFFF"..(currentPower or 0).."|r/|c0000FF00"..totalPower.."|r/|c00FFFF00"..worldQuestPower.."|r/|c00FF8C00"..worldQuestPowerLooseSoon.."|r/"..(powerNextLevel or 0)..")";
end

function f:GetArtifactInfos()
	local itemID, altItemID, name, icon, totalXP, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo();
	 if(pointsSpent == nil) then return; end
	local numPointsAvailableToSpend, xp , xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP);

	currentPower = xp;
	powerNextLevel = xpForNextPoint;
	
	

end

function f:GetItemLinkArtifactPower(itemLink)
    if itemLink then
        local itemSpell = GetItemSpell(itemLink)
        if itemSpell and itemSpell == empoweringSpellName then
            tooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
            tooltipScanner:SetHyperlink (itemLink)
			local tooltipText = _G[tooltipName.."TextLeft4"]:GetText()
			
			if(tooltipText == nil) then
				return nil
			end
            local ap = tooltipText:gsub("[,%.]", ""):match("%d.-%s") or ""
            
            tooltipScanner:Hide()			
            return tonumber(ap);
        else
            return nil
        end
    else
        return nil
    end

end




f:OnLoad();
