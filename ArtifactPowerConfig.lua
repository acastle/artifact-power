local config = CreateFrame("Frame");
local excludeList = {
	[LE_QUEST_TAG_TYPE_PROFESSION] = "Profession",
	[LE_QUEST_TAG_TYPE_PVP] = "PvP",
	[LE_QUEST_TAG_TYPE_PET_BATTLE] = "Pet Battle",
	[LE_QUEST_TAG_TYPE_DUNGEON] = "Dungeon",
}
local defaultconf = {
["GlobalConf"]=true, 
["ExcludeList"] = {
	[LE_QUEST_TAG_TYPE_PROFESSION] = false,
	[LE_QUEST_TAG_TYPE_PVP] = false,
	[LE_QUEST_TAG_TYPE_PET_BATTLE] = false,
	[LE_QUEST_TAG_TYPE_DUNGEON] = false,
},
["DisplayString"] = "(#currentPower#/#bagPower#/#worldQuestPower#/#worldQuestPowerLooseSoon#/#powerNextLevel#)",
["colorpowerNextLevel"] = {
		0.803921568627451, -- [1]
		0.694117647058824, -- [2]
		0, -- [3]
		1, -- [4]
	},	
	["colorcurrentPower"] = {
		0.87843137254902, -- [1]
		1, -- [2]
		0.968627450980392, -- [3]
		1, -- [4]
	},
	["GlobalConf"] = true,
	["colorworldQuestPower"] = {
		1, -- [1]
		0.956862745098039, -- [2]
		0.0901960784313726, -- [3]
		1, -- [4]
	},
	["colorbagPower"] = {
		0, -- [1]
		1, -- [2]
		0.0509803921568627, -- [3]
		1, -- [4]
	},
	["colorworldQuestPowerLooseSoon"] = {
		0.992156862745098, -- [1]
		0.580392156862745, -- [2]
		0, -- [3]
		1, -- [4]
	},
	["colorpowerNextLevelLeft"] = {
		0.992156862745098, -- [1]
		0, -- [2]
		0, -- [3]
		1, -- [4]
	}
	
}
local config2 = CreateFrame("Frame");
local addonName,ns = ...
local lastattached={};
ns.config = {};
ns.configFrame = config;
local metatable = {};

metatable.__index = function( inTable, inKey )
  value = defaultconf[inKey];
  inTable[ inKey ] = value;
  return value;
end

local function CreateCheckbox(wframe,button_name,button_text,button_helper_text)
	 local newcheckbox = CreateFrame( "CheckButton", "ArtifactPower_"..button_name, wframe, "InterfaceOptionsCheckButtonTemplate" );
	 wframe[button_name] = newcheckbox;
	 newcheckbox.id = button_name;
	 if( not lastattached[wframe.name]) then
		newcheckbox:SetPoint( "TOPLEFT", 16, -16 );
	else
		newcheckbox:SetPoint("TOPLEFT", lastattached[wframe.name],"BOTTOMLEFT", 0, -5);
	end
	 newcheckbox:SetScript("onClick",config.ChangeState);
	 _G[ newcheckbox:GetName().."Text" ]:SetText( "|c00dfb802"..button_text );
	 
	 lastattached[wframe.name] = newcheckbox;
	 
	 if(button_helper_text) then
		local newcheckboxexplain = wframe:CreateFontString( nil, "OVERLAY", "GameFontHighlight" );
		wframe[button_name.."Explain"] = newcheckboxexplain;
		newcheckboxexplain:SetPoint("TOPLEFT", lastattached[wframe.name],"BOTTOMLEFT", 0, 0)
		newcheckboxexplain:SetWidth(InterfaceOptionsFramePanelContainer:GetRight() - InterfaceOptionsFramePanelContainer:GetLeft() - 30);
		newcheckboxexplain:SetJustifyH("LEFT");
		newcheckboxexplain:SetText( button_helper_text);
		lastattached[wframe.name] = newcheckboxexplain;
	 end

end

function config:Init()
	config2.name = "Artifact Power";
	config2:SetScript("OnShow",function () InterfaceOptionsFrame_OpenToCategory(config); end);
	InterfaceOptions_AddCategory(config2);
	
	config.name = "Basic Options";
	config.parent="Artifact Power";
	
	CreateCheckbox(config,"GlobalConf","Global Configuration","If checked this character uses the global configuration, uncheck to use different options for this character");
	
	
	local AceGUI = LibStub("AceGUI-3.0")
	
	
	
	
	InterfaceOptions_AddCategory(config);
	
	if not(ArtifactPowerGlobalConfig) then
		ArtifactPowerGlobalConfig =  defaultconf;
		ArtifactPowerLocalConfig = defaultconf;
	end
	if not(ArtifactPowerLocalConfig) then
		ArtifactPowerLocalConfig = defaultconf;
	end
	
	
	setmetatable(ArtifactPowerGlobalConfig,metatable);
	setmetatable(ArtifactPowerLocalConfig,metatable);
	
	if(ArtifactPowerLocalConfig.GlobalConf==true) then
		ns.config = ArtifactPowerGlobalConfig;
	else
		ns.config = ArtifactPowerLocalConfig;
	end
	
	local excludeListConfig = AceGUI:Create("Dropdown")
		excludeListConfig.frame:SetParent(config);
		excludeListConfig:SetLabel("Exclude the following types of possible Artifact Power gain");
		excludeListConfig:SetList(excludeList)
		excludeListConfig:SetMultiselect(true)
		excludeListConfig:SetPoint( "TOPLEFT" , lastattached[config.name],"BOTTOMLEFT",0,0);
		for key, val in pairs(ns.config.ExcludeList) do
			excludeListConfig:SetItemValue(key,val)
		end
		excludeListConfig.frame:Show(true)
		
		excludeListConfig:SetCallback("OnValueChanged",function(self,event,key,checked)
			ns.config.ExcludeList[key] = checked
		end)
	
	local textString = AceGUI:Create("EditBox")
		
		textString.frame:SetParent(config);
		textString:SetWidth(600)
		textString:SetLabel("Text to show in Broker");
		textString:SetPoint( "TOPLEFT", excludeListConfig.frame, "BOTTOMLEFT", 0, 0);
		textString:SetText(ns.config.DisplayString)
		
		textString.frame:Show(true)
		textString:SetCallback("OnEnterPressed",function(self,event,value)
			ns.config.DisplayString = value;		
			end)
			
	local colorCurrentPower = AceGUI:Create("ColorPicker")
		colorCurrentPower.frame:SetParent(config);
		colorCurrentPower:SetLabel("#currentPower#");
		colorCurrentPower:SetHasAlpha(true);
		colorCurrentPower:SetPoint( "TOPLEFT" , textString.frame,"BOTTOMLEFT",0,0);
		colorCurrentPower.frame:Show(true)
		colorCurrentPower:SetWidth(300)
		colorCurrentPower:SetColor(unpack(ns.config.colorcurrentPower));
		colorCurrentPower:SetCallback("OnValueConfirmed",function(self,event,r,g,b,a)
			ns.config.colorcurrentPower = {r,g,b,a}
		end)
		
	local colorBagPower = AceGUI:Create("ColorPicker")
		colorBagPower.frame:SetParent(config);
		colorBagPower:SetLabel("#bagPower#");
		colorBagPower:SetHasAlpha(true);
		colorBagPower:SetPoint("TOPLEFT" , colorCurrentPower.frame,"BOTTOMLEFT",0,0);
		colorBagPower.frame:Show(true)
		colorBagPower:SetWidth(300)
		colorBagPower:SetColor(unpack(ns.config.colorbagPower));
		colorBagPower:SetCallback("OnValueConfirmed",function(self,event,r,g,b,a)
			ns.config.colorbagPower = {r,g,b,a}
		end)
		
	local colorWorldQuestPower = AceGUI:Create("ColorPicker")
		colorWorldQuestPower.frame:SetParent(config);
		colorWorldQuestPower:SetLabel("#worldQuestPower#");
		colorWorldQuestPower:SetHasAlpha(true);
		colorWorldQuestPower:SetPoint( "TOPLEFT" , colorBagPower.frame,"BOTTOMLEFT",0,0);
		colorWorldQuestPower.frame:Show(true)
		colorWorldQuestPower:SetWidth(300)
		colorWorldQuestPower:SetColor(unpack(ns.config.colorworldQuestPower));
		colorWorldQuestPower:SetCallback("OnValueConfirmed",function(self,event,r,g,b,a)
			ns.config.colorworldQuestPower = {r,g,b,a}
		end)
		
	local colorWorldQuestPowerLooseSoon = AceGUI:Create("ColorPicker")
		colorWorldQuestPowerLooseSoon.frame:SetParent(config);
		colorWorldQuestPowerLooseSoon:SetLabel("#worldQuestPowerLooseSoon#");
		colorWorldQuestPowerLooseSoon:SetHasAlpha(true);
		colorWorldQuestPowerLooseSoon:SetPoint( "TOPLEFT" , colorWorldQuestPower.frame,"BOTTOMLEFT",0,0);
		colorWorldQuestPowerLooseSoon.frame:Show(true)
		colorWorldQuestPowerLooseSoon:SetWidth(300)
		colorWorldQuestPowerLooseSoon:SetColor(unpack(ns.config.colorworldQuestPowerLooseSoon));
		colorWorldQuestPowerLooseSoon:SetCallback("OnValueConfirmed",function(self,event,r,g,b,a)
			ns.config.colorworldQuestPowerLooseSoon = {r,g,b,a}
		end)
		
	local colorPowerNextLevel = AceGUI:Create("ColorPicker")
		colorPowerNextLevel.frame:SetParent(config);
		colorPowerNextLevel:SetLabel("#powerNextLevel#");
		colorPowerNextLevel:SetHasAlpha(true);
		colorPowerNextLevel:SetWidth(300)
		colorPowerNextLevel:SetPoint( "TOPLEFT" , colorWorldQuestPowerLooseSoon.frame,"BOTTOMLEFT",0,0);
		colorPowerNextLevel.frame:Show(true)
		colorPowerNextLevel:SetColor(unpack(ns.config.colorpowerNextLevel));
		colorPowerNextLevel:SetCallback("OnValueConfirmed",function(self,event,r,g,b,a)
			ns.config.colorpowerNextLevel = {r,g,b,a}
		end)
		
	local colorPowerNextLevelLeft = AceGUI:Create("ColorPicker")
		colorPowerNextLevelLeft.frame:SetParent(config);
		colorPowerNextLevelLeft:SetLabel("#powerNextLevelLeft#");
		colorPowerNextLevelLeft:SetHasAlpha(true);
		colorPowerNextLevelLeft:SetWidth(300)
		colorPowerNextLevelLeft:SetPoint( "TOPLEFT" , colorPowerNextLevel.frame,"BOTTOMLEFT",0,0);
		colorPowerNextLevelLeft.frame:Show(true)
		colorPowerNextLevelLeft:SetColor(unpack(ns.config.colorpowerNextLevelLeft));
		colorPowerNextLevelLeft:SetCallback("OnValueConfirmed",function(self,event,r,g,b,a)
			ns.config.colorpowerNextLevelLeft = {r,g,b,a}
		end)
	if not ns.config.frame_secure_pos then
		ns.config.frame_secure_pos = {};
	end
	
	config:SetCurrentConfig();
end


function config:SetCurrentConfig()
	for key, _ in pairs(defaultconf) do
		if(key == "GlobalConf") then	
			_G["ArtifactPower_"..key]:SetChecked(ns.config[key])
		end
		
	end
end


function config:ChangeState()
	if(self.id=="GlobalConf") then
		ArtifactPowerLocalConfig["GlobalConf"] = self:GetChecked();
		if(self:GetChecked()==true) then
			ns.config = ArtifactPowerGlobalConfig;
		else
			if not(ArtifactPowerLocalConfig) then
				ArtifactPowerLocalConfig = ArtifactPowerGlobalConfig;
				
				
			end
			ns.config = ArtifactPowerLocalConfig;
		end
		config:SetCurrentConfig();
	else
		ns.config[self.id] = self:GetChecked();		
	end
end