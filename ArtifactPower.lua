local tooltipScanner
local tooltipName = "ArtifactPowerTooltipScanner"
local totalPower,currentPower,worldQuestPower,worldQuestPowerLooseSoon,powerNextLevel;
local f  = CreateFrame("frame",nil,UIParent);
local numberOverlay = {};
local ldb =  LibStub:GetLibrary("LibDataBroker-1.1");
local ldbPower;
local brokenIslesZones = {};


function f:OnLoad()
   
	f:SetScript("OnEvent",f.EventHandler);	
	f:RegisterEvent("BAG_UPDATE_DELAYED");	
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
	end

end

function f:ScanWorldQuests()
	local index,value,worldQuests,timeLeft,i,itemLink,ap,itemID,_;
	worldQuestPower = 0;
	worldQuestPowerLooseSoon = 0;
	for index,value in pairs(brokenIslesZones) do			
		if tonumber(value) ~= nil then
			SetMapByID(value)
			worldQuests = C_TaskQuest.GetQuestsForPlayerByMapID(value)
			if worldQuests then					
				for i = 1, #worldQuests do
					timeLeft = C_TaskQuest.GetQuestTimeLeftMinutes(worldQuests[i].questId)
					if timeLeft > 0 then
						questId = worldQuests[i].questId
						if GetNumQuestLogRewards(questId) > 0 then
							_, _, _, _, _, itemID = GetQuestLogRewardInfo (1, questId)
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

function f:ShowText()
	ldbPower.text = "(|c00FFFFFF"..currentPower.."|r/|c0000FF00"..totalPower.."|r/|c00FFFF00"..worldQuestPower.."|r/|c00FF8C00"..worldQuestPowerLooseSoon.."|r/"..powerNextLevel..")";
end

function f:GetArtifactInfos()
	local itemID, altItemID, name, icon, totalXP, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo();
	local numPointsAvailableToSpend, xp , xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP);

	currentPower = xp;
	powerNextLevel = xpForNextPoint;
	
	

end

function f:GetItemLinkArtifactPower(itemLink)
    if itemLink then
        local itemSpell = GetItemSpell(itemLink)
        if itemSpell and itemSpell == "Empowering" then
            tooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
            tooltipScanner:SetHyperlink (itemLink)
			local tooltipText = _G[tooltipName.."TextLeft4"]:GetText()
			
			if(tooltipText == nil) then
				return nil
			end
            local ap = tooltipText:match("%d.-%s") or ""
            
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
