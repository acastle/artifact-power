local config = CreateFrame("Frame");
local defaultconf = {["IncludePvP"]=true,["GlobalConf"]=true}
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
	CreateCheckbox(config,"IncludePvP","Include PvP Worldquest","If unchecked possible gain from Worldquest will exclude PvP Worldquest in the calculation");
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
	config:SetCurrentConfig();
end


function config:SetCurrentConfig()
	for key, _ in pairs(defaultconf) do
		_G["ArtifactPower_"..key]:SetChecked(ns.config[key]);
		
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