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
function f:OnLoad()
	empoweringSpellName = GetSpellInfo(EMPOWERING_SPELL_ID)
	f:SetScript("OnEvent",f.EventHandler);	
	f:RegisterEvent("BAG_UPDATE_DELAYED");	
	f:RegisterEvent("ADDON_LOADED");
	--f:RegisterEvent("ARTIFACT_UPDATE")
	
	f:RegisterEvent("QUEST_LOG_UPDATE");

	
	tooltipScanner = CreateFrame("GameTooltip", tooltipName, nil, "GameTooltipTemplate")
	ldbPower = ldb:NewDataObject("Artifact Power", { type = "data source", label ="Artifact Power", text = "", icon = "Interface\\ICONS\\INV_Artifact_XP05"});
	brokenIslesZones =  { GetMapZones(8) } ;
end


function f:CheckBags()	
	f:GetArtifactInfos()
	f:ScanWorldQuests();
	apStats.bagPower = 0;
	local itemLink,powerGain,rawPowerGain;
	for bag = 0, 4 do	
		for slot = 1, GetContainerNumSlots(bag) do
			itemLink = GetContainerItemLink(bag, slot)
			powerGain = f:GetItemLinkArtifactPower(itemLink);
			if(powerGain~=nil) then
				apStats.bagPower = apStats.bagPower + powerGain	
			
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
	local index,value,worldQuests,timeLeft,i,itemLink,ap,itemID,worldQuestType,isPvP,_;
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
	
end

function f:GetArtifactInfos()	
	
	local itemID, altItemID, name, icon, totalXP, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo();
	 if(pointsSpent == nil) then return; end
	local numPointsAvailableToSpend, xp , xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP);

	apStats.currentPower = xp;
	apStats.powerNextLevel = xpForNextPoint;
	
	

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
