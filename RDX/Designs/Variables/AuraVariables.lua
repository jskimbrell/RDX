-- AuraInfo.lua
-- OpenRDX
-- Sigg

-------------------------------------
-- Buff Debuff Info by Sigg Rashgarroth eu
-------------------------------------

local i, name, icon, apps, dur, expirationTime, caster, fdur, ftimeleft, possible, start, bn;

function __rdxloadbuff(uid, buffname, auracache, playerauras, othersauras, petauras, targetauras, focusauras)
	i, name, icon, apps, dur, expirationTime, caster, fdur, ftimeleft, possible, start, bn = 1, nil, "", nil, nil, nil, nil, 0, 0, false, 0, nil;
	if type(buffname) == "number" then
		bn = GetSpellInfo(buffname);
		if not bn then bn = buffname; end
	else
		bn = buffname;
	end
	name, _, icon, apps, _, dur, expirationTime, caster, isStealable = UnitAura(uid, bn);
	if (name == bn) then
		possible = true;
		if dur and dur > 0 then
			fdur = dur;
			ftimeleft = expirationTime - GetTime();
			start = expirationTime - dur;
		else
			fdur = 0;
			ftimeleft = 0;
			start = 0;
		end
		if (playerauras and caster ~= "player") or (othersauras and caster == "player") or (petauras and caster ~= "pet") or (targetauras and caster ~= "target") or (focusauras and caster ~= "focus") then
			fdur = 0;
			ftimeleft = 0;
			start = 0;
			possible = false;
		end
	end
	return possible, apps, icon, start, fdur, caster, timeleft;
end

function __rdxloaddebuff(uid, debuffname, auracache, playerauras, othersauras, petauras, targetauras, focusauras)
	i, name, icon, apps, dur, expirationTime, caster, fdur, ftimeleft, possible, start, bn = 1, nil, "", nil, nil, nil, nil, 0, 0, false, 0, nil;
	if type(debuffname) == "number" then
		bn = GetSpellInfo(debuffname);
		if not bn then bn = debuffname; end
	else
		bn = debuffname;
	end
	name, _, icon, apps, _, dur, expirationTime, caster, isStealable = UnitDebuff(uid, bn);
	if (name == bn) then
		possible = true;
		if dur and dur > 0 then
			fdur = dur;
			ftimeleft = expirationTime - GetTime();
			start = expirationTime - dur;
		else
			fdur = 0;
			ftimeleft = 0;
			start = 0;
		end
		if (playerauras and caster ~= "player") or (othersauras and caster == "player") or (petauras and caster ~= "pet") or (targetauras and caster ~= "target") or (focusauras and caster ~= "focus") then
			fdur = 0;
			ftimeleft = 0;
			start = 0;
			possible = false;
		end
	end
	return possible, apps, icon, start, fdur, caster, timeleft;
end

local _types = {
	{ text = "BUFFS" },
	{ text = "DEBUFFS" },
};
local function _dd_types() return _types; end

RDX.RegisterFeature({
	name = "Variables: Buffs Debuffs Info";
	title = VFLI.i18n("Vars Aura Info");
	category =  VFLI.i18n("Variables");
	multiple = true;
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("EmitPaintPreamble") then return nil; end
		return true;
	end;
	ExposeFeature = function(desc, state, errs)		
		if not desc then VFL.AddError(errs, VFLI.i18n( "No descriptor.")); return nil; end
		if not desc.cd then VFL.AddError(errs, VFLI.i18n( "No aura selected.")); return nil; end
		state:AddSlot("BoolVar_" .. desc.name .."_possible");
		state:AddSlot("TimerVar_" .. desc.name .."_aura");
		state:AddSlot("TextData_" .. desc.name .."_aura_name");
		state:AddSlot("TextData_" .. desc.name .."_aura_stack");
		state:AddSlot("NumberVar_" .. desc.name .. "_stack");
		--state:AddSlot("TextData_" .. desc.name .."_aura_caster");
		state:AddSlot("TexVar_" .. desc.name .."_icon");
		state:AddSlot("Var_" .. desc.name .. "_timeleft");
		return true;
	end;
	ApplyFeature = function(desc, state)
		local playerauras = "false"; if desc.playerauras then playerauras = "true"; end
		local othersauras = "false"; if desc.othersauras then othersauras = "true"; end
		local petauras = "false"; if desc.petauras then petauras = "true"; end
		local targetauras = "false"; if desc.targetauras then targetauras = "true"; end
		local focusauras = "false"; if desc.focusauras then focusauras = "true"; end
		local loadCode = "__rdxloadbuff";
		local reverse = "true" if desc.reverse then reverse = "false"; end
		
		-- Event hinting.
		local mux = state:GetContainingWindowState():GetSlotValue("Multiplexer");
		local mask = 0; 
		if desc.auraType == "DEBUFFS" then
			mask = mux:GetPaintMask("DEBUFFS");
			mux:Event_UnitMask("UNIT_DEBUFF_*", mask);
			loadCode = "__rdxloaddebuff";
		else
			mask = mux:GetPaintMask("BUFFS");
			mux:Event_UnitMask("UNIT_BUFF_*", mask);
		end
		
		local tcd = nil;
		if type(desc.cd) == "number" then
			tcd = desc.cd;
		else
			tcd = [["]] .. desc.cd .. [["]];
		end
		
		local winpath = state:GetContainingWindowState():GetSlotValue("Path");
		local md = RDXDB.GetObjectData(winpath);
		local auracache = "false"; if md and RDXDB.HasFeature(md.data, "AuraCache") then auracache = "true"; end
		
		state:Attach(state:Slot("EmitPaintPreamble"), true, function(code)
			code:AppendCode([[
local ]] .. desc.name .. [[_possible, ]] .. desc.name .. [[_stack, ]] .. desc.name .. [[_icon , ]] .. desc.name .. [[_aura_start, ]] .. desc.name .. [[_aura_duration, ]] .. desc.name .. [[_caster, ]] .. desc.name .. [[_timeleft = ]] .. loadCode .. [[(uid, ]] .. tcd .. [[, ]] .. auracache .. [[, ]] .. playerauras .. [[, ]] .. othersauras .. [[, ]] .. petauras .. [[, ]] .. targetauras .. [[, ]] .. focusauras .. [[);
local ]] .. desc.name .. [[_aura_name = "";
local ]] .. desc.name .. [[_aura_stack = 0;
local ]] .. desc.name .. [[_aura_caster = "";
if not ]] .. reverse .. [[ then
	]] .. desc.name .. [[_possible = not ]] .. desc.name .. [[_possible;
end
if ]] .. desc.name .. [[_possible then
	]] .. desc.name .. [[_aura_name = "]] .. desc.name .. [[";
end
if not ]] .. desc.name .. [[_stack then ]] .. desc.name .. [[_stack = 0; end
if ]] .. desc.name .. [[_stack > 0 then
	]] .. desc.name .. [[_aura_stack = ]] .. desc.name .. [[_stack;
end
--if ]] .. desc.name .. [[_caster and ]] .. desc.name .. [[_caster ~= "" then
--	local unitu = RDXDAL._ReallyFastProject(]] .. desc.name .. [[_caster);
--	if unitu then
--		]] .. desc.name .. [[_aura_caster = unitu:GetName();
--	else
--		]] .. desc.name .. [[_aura_caster = ]] .. desc.name .. [[_caster;
--	end
--end
]]);
		end);
	end;
	UIFromDescriptor = function(desc, parent, state)
		local ui = VFLUI.CompoundFrame:new(parent);
		
		local iname = VFLUI.LabeledEdit:new(ui, 100); 
		iname:Show();
		iname:SetText(VFLI.i18n("Variable Name"));
		if desc and desc.name then iname.editBox:SetText(desc.name); end
		ui:InsertFrame(iname);
		
		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Aura Type:"));
		local dd_auraType = VFLUI.Dropdown:new(er, _dd_types);
		dd_auraType:SetWidth(150); dd_auraType:Show();
		if desc and desc.auraType then 
			dd_auraType:SetSelection(desc.auraType); 
		else
			dd_auraType:SetSelection("BUFFS");
		end
		er:EmbedChild(dd_auraType); er:Show();
		ui:InsertFrame(er);
		
		local cd = VFLUI.LabeledEdit:new(ui, 150);
		cd:SetText(VFLI.i18n("Aura Name"));
		cd:Show();
		if desc and desc.cd then 
			if type(desc.cd) == "number" then
				local name = GetSpellInfo(desc.cd);
				cd.editBox:SetText(name);
			else
				cd.editBox:SetText(desc.cd);
			end
		end
		ui:InsertFrame(cd);
		
		local btn = VFLUI.Button:new(cd);
		btn:SetHeight(25); btn:SetWidth(25); btn:SetText("...");
		btn:SetPoint("RIGHT", cd.editBox, "LEFT"); 
		btn:Show();
		if dd_auraType:GetSelection() == "BUFFS" then 
			btn:SetScript("OnClick", function()
				RDXDAL.AuraCachePopup(RDXDAL._GetBuffCache(), function(x) 
					if x then cd.editBox:SetText(x.properName); end
				end, btn, "CENTER");
			end);
		else
			btn:SetScript("OnClick", function()
				RDXDAL.AuraCachePopup(RDXDAL._GetDebuffCache(), function(x) 
					if x then cd.editBox:SetText(x.properName); end
				end, btn, "CENTER");
			end);
		end
		
		------------ Filter
		ui:InsertFrame(VFLUI.Separator:new(ui, VFLI.i18n("Filtering")));
		
		local chk_playerauras = VFLUI.Checkbox:new(ui); chk_playerauras:Show();
		chk_playerauras:SetText(VFLI.i18n("Filter auras by player"));
		if desc and desc.playerauras then chk_playerauras:SetChecked(true); else chk_playerauras:SetChecked(); end
		ui:InsertFrame(chk_playerauras);
		
		local chk_othersauras = VFLUI.Checkbox:new(ui); chk_othersauras:Show();
		chk_othersauras:SetText(VFLI.i18n("Filter auras by other players"));
		if desc and desc.othersauras then chk_othersauras:SetChecked(true); else chk_othersauras:SetChecked(); end
		ui:InsertFrame(chk_othersauras);

		local chk_petauras = VFLUI.Checkbox:new(ui); chk_petauras:Show();
		chk_petauras:SetText(VFLI.i18n("Filter auras by pet/vehicle"));
		if desc and desc.petauras then chk_petauras:SetChecked(true); else chk_petauras:SetChecked(); end
		ui:InsertFrame(chk_petauras);
		
		local chk_targetauras = VFLUI.Checkbox:new(ui); chk_targetauras:Show();
		chk_targetauras:SetText(VFLI.i18n("Filter auras by target"));
		if desc and desc.targetauras then chk_targetauras:SetChecked(true); else chk_targetauras:SetChecked(); end
		ui:InsertFrame(chk_targetauras);
		
		local chk_focusauras = VFLUI.Checkbox:new(ui); chk_focusauras:Show();
		chk_focusauras:SetText(VFLI.i18n("Filter auras by focus"));
		if desc and desc.focusauras then chk_focusauras:SetChecked(true); else chk_focusauras:SetChecked(); end
		ui:InsertFrame(chk_focusauras);
        
		local chk_reverse = VFLUI.Checkbox:new(ui); chk_reverse:Show();
		chk_reverse:SetText(VFLI.i18n("Reverse filtering (report when NOT possible)"));
		if desc and desc.reverse then chk_reverse:SetChecked(true); else chk_reverse:SetChecked(); end
		ui:InsertFrame(chk_reverse);

		function ui:GetDescriptor()
			local t = cd.editBox:GetText();
			return {
				feature = "Variables: Buffs Debuffs Info"; 
				name = iname.editBox:GetText();
				auraType = dd_auraType:GetSelection();
				cd = RDXSS.GetSpellIdByLocalName(t) or t;
				playerauras = chk_playerauras:GetChecked();
				othersauras = chk_othersauras:GetChecked();
				petauras = chk_petauras:GetChecked();
				targetauras = chk_targetauras:GetChecked();
				focusauras = chk_focusauras:GetChecked();
				reverse = chk_reverse:GetChecked();
			};
		end
		
		ui.Destroy = VFL.hook(function(s) btn:Destroy(); s.GetDescriptor = nil; end, ui.Destroy);

		return ui;
	end;
	CreateDescriptor = function()
		return { feature = "Variables: Buffs Debuffs Info"; name = "aurai"; auraType = "BUFFS"; };
	end;
});
