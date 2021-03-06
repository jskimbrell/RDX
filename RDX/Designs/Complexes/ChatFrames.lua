-- ChatFrames.lua
-- OpenRDX
-- Sigg Rashgarroth EU

-----------------------------------------------
-- ChatFrame
-----------------------------------------------

-- fedd table message when opening for copy past
local msgmax = 100;
local msgtable1, msgtable3, msgtable4 = {}, {}, {};
local n, msglink;

-- fedd table editor

local function EditScriptDialog(parent, key)
	-- Sanity checks
	local ctype, font = nil, nil;

	local dlg = VFLUI.Window:new(parent);
	VFLUI.Window.SetDefaultFraming(dlg, 22);
	dlg:SetTitleColor(0,0,.6);
	dlg:SetBackdrop(VFLUI.BlackDialogBackdrop);
	dlg:SetPoint("CENTER", VFLParent, "CENTER");
	dlg:SetWidth(500); dlg:SetHeight(500);
	dlg:SetText(VFLI.i18n("Text Editor: "));
	dlg:Show();
	VFLUI.Window.StdMove(dlg, dlg:GetTitleBar());

	local editor = VFLUI.TextEditor:new(dlg, ctype, font);
	editor:SetPoint("TOPLEFT", dlg:GetClientArea(), "TOPLEFT");
	editor:SetWidth(490); editor:SetHeight(430); editor:Show();
	msglink = "";
	if key == "1" then
		for _,v in ipairs(msgtable1) do
			msglink = msglink .. v .. "\n";
		end
		editor:SetText( msglink or "");
	end
	editor:GetEditWidget():SetFocus();

	local esch = function() dlg:Destroy(); end
	VFL.AddEscapeHandler(esch);

	local btnClose = VFLUI.CloseButton:new(dlg);
	dlg:AddButton(btnClose);
	btnClose:SetScript("OnClick", function() VFL.EscapeTo(esch); end);

	dlg.Destroy = VFL.hook(function(s)
		editor:Destroy(); editor = nil;
	end, dlg.Destroy);
end

local function FeedTables(key, msg)
	if key == 1 then 
		if(#msgtable1 >= msgmax) then table.remove(msgtable1, 1); end
		table.insert(msgtable1, msg);
	elseif key == 3 then
		if(#msgtable3 >= msgmax) then table.remove(msgtable3, 1); end
		table.insert(msgtable3, msg);
	elseif key == 4 then
		if(#msgtable4 >= msgmax) then table.remove(msgtable4, 1); end
		table.insert(msgtable4, msg);
	end
end

-- hide, scroll

local function hide(self) self:Hide() end

local function scroll(self, arg1)
	if arg1 > 0 then
		if IsShiftKeyDown() then
			self:ScrollToTop();
		elseif IsControlKeyDown() then
			self:PageUp();
		else
			self:ScrollUp();
		end
	elseif arg1 < 0 then
		if IsShiftKeyDown() then
			self:ScrollToBottom();
		elseif IsControlKeyDown() then
			self:PageDown();
		else
			self:ScrollDown();
		end
	end
end

-- From Basic Chat Mod by funkydude
local gsub = string.gsub;
local AddStringDate = VFL.AddStringDate;

local channels = {
	--standard channels replaced below
	["%[Guild%]"] = "|cffff3399[|rG|cffff3399]|r",
	["%[Party%]"] = "|cffff3399[|rP|cffff3399]|r",
	["%[Party Leader%]"] = "|cffff3399[|rPL|cffff3399]|r",
	["%[Raid%]"] = "|cffff3399[|rR|cffff3399]|r",
	["%[Raid Leader%]"] = "|cffff3399[|rRL|cffff3399]|r",
	["%[Raid Warning%]"] = "|cffff0000[|rRW|cffff0000]|r",
	["%[Officer%]"] = "|cffff0000[|rO|cffff0000]|r",
	["%[%d+%. WorldDefense%]"] = "|cff990066[|rWD|cff990066]|r",
	["%[%d+%. LookingForGroup%]"] = "|cff990066[|rLFG|cff990066]|r",
	["%[%d+%. General%]"] = "|cff990066[|r1|cff990066]|r",
	["%[%d+%. LocalDefense%]"] = "|cff990066[|r3|cff990066]|r",
	["%[%d+%. Trade%]"] = "|cff990066[|r2|cff990066]|r",
	["%[%d+%. GuildRecruitment %- .*%]"] = "|cff990066[|r4|cff990066]|r",
	["%[Battleground%]"] = "|cffff3399[|rBG|cffff3399]|r",
	["%[Battleground Leader%]"] = "|cffff0000[|rBGL|cffff0000]|r",
}

local channelsI = channels;

if GetLocale() == "frFR" and VFL.ChannelfrFR then
	channelsI = VFL.ChannelfrFR;
end

local function changeMessage(frame, msg, ...)
	if type(msg) == "string" then
		if msg and msg ~= "" then
			if frame.channel then 
				for k, v in pairs(channelsI) do
					msg = gsub(msg, k, v);
				end
				--custom channels replaced below
				msg = gsub(msg, "%[(%w+)%.%s(%w*)%]", "|cffff0000[|r%1|cffff0000]|r");
			end
			msg = VFL.AddStringDate(msg, frame.ts, frame.color);
		end
		FeedTables(frame.key, msg);
		frame:RDX_AddMessage(msg, ...)
	end
end

VFLUI.CreateFramePool("ChatFrame", 
	function(pool, x) -- on released
		if (not x) then return; end
		x:Hide();
		x.AddMessage = x.RDX_AddMessage;
		VFLUI._CleanupLayoutFrame(x);
	end,
	function(_, key) -- on fallback
		local f = nil;
		if key > 0 and key < 11 then
			f = _G[format("%s%d", "ChatFrame", key)];
			
			if key == 1 then
				ChatFrame2:Hide();
				ChatFrame2:SetScript("OnShow", hide);
				ChatFrame2Tab:Hide();
				ChatFrame2Tab:SetScript("OnShow", hide);
			end
			
			-- Hide buttons
			--if key > 0 and key < 11 then
			--	local chat = _G[format("%s%d%s", "ChatFrame", key, "Tab")];
			--	chat:UnregisterAllEvents();
			--	chat:Hide();
			--end
			--local up = _G[format("%s%d%s", "ChatFrame", key, "ButtonFrameUpButton")];
			--up:SetScript("OnShow", hide);
			--up:Hide();
			--local down = _G[format("%s%d%s", "ChatFrame", key, "ButtonFrameDownButton")];
			--down:SetScript("OnShow", hide);
			--down:Hide();
			--local bottom = _G[format("%s%d%s", "ChatFrame", key, "ButtonFrameBottomButton")];
			--bottom:SetScript("OnShow", hide);
			--bottom:Hide();
			local cab = _G[format("%s%d%s", "ChatFrame", key, "ClickAnywhereButton")];
			cab:SetScript("OnShow", hide);
			cab:Hide();
			
			local rb = _G[format("%s%d%s", "ChatFrame", key, "ResizeButton")];
			rb:SetScript("OnShow", hide);
			rb:Hide();
			
			local bf = _G[format("%s%d%s", "ChatFrame", key, "ButtonFrame")];
			bf:SetScript("OnShow", hide);
			bf:Hide();
			
			local tab = _G[format("%s%d%s", "ChatFrame", key, "Tab")];
			tab:SetScript("OnShow", hide);
			tab:UnregisterAllEvents();
			tab:Hide();
			
			
			-- scroll
			f:SetScript("OnMouseWheel", scroll);
			f:EnableMouseWheel(true);
			f:SetClampedToScreen(false);
			
			
			-- unregistered event
			--f:UnregisterEvent("UPDATE_CHAT_WINDOWS");
			
			-- timestamp
			f.SetMsg = function(frame, ts, color, channel)
				frame.key = key;
				frame.ts = ts;
				frame.color = color;
				frame.channel = channel;
				frame.AddMessage = changeMessage;
			end
			
		end
		return f;
	end, 
	function(_, f) -- on acquired
		f.RDX_AddMessage = f.AddMessage;
		FCF_SetLocked(f, nil);
		FCF_UnDockFrame(f);
		f:ClearAllPoints();
		f:Show();
	end,
"key");

local numberlist = {
	{ text = "1" },
	--{ text = "2" },
	{ text = "3" },
	{ text = "4" },
	{ text = "5" },
	{ text = "6" },
	{ text = "7" },
	{ text = "8" },
	{ text = "9" },
	{ text = "10" },
};
local function amOnBuild() return numberlist; end
RDXUI.NumberListSelectionFunc = amOnBuild;


RDX.RegisterFeature({
	name = "chatframe";
	multiple = true;
	version = 1;
	title = VFLI.i18n("ChatFrame");
	category = VFLI.i18n("Complexes");
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("Base") then return nil; end
		return true;
	end;
	ExposeFeature = function(desc, state, errs)
		if not desc then VFL.AddError(errs, VFLI.i18n("Missing descriptor.")); return nil; end
		if desc.owner == "Base" then desc.owner = "decor"; end
		local flg = true;
		flg = flg and RDXUI.UFFrameCheck_Proto("Frame_", desc, state, errs);
		flg = flg and RDXUI.UFAnchorCheck(desc.anchor, state, errs);
		flg = flg and RDXUI.UFOwnerCheck(desc.owner, state, errs);
		if flg then state:AddSlot("Frame_" .. desc.name); end
		return flg;
	end;
	ApplyFeature = function(desc, state)
		local objname = "Frame_" .. desc.name;
		
		state:GetContainingWindowState():Attach("Menu", true, function(win, mnu)
			table.insert(mnu, {
				text = VFLI.i18n("Edit ChatFrame: ".. desc.number);
				OnClick = function()
					VFL.poptree:Release();
					CURRENT_CHAT_FRAME_ID = tonumber(desc.number);
					ToggleDropDownMenu(1, nil, _G["ChatFrame" .. desc.number .. "Tab" .. "DropDown"], "ChatFrame" .. desc.number .. "Tab", 0, 0);
				end;
			});
		end);
		
		state:GetContainingWindowState():Attach("Menu", true, function(win, mnu)
			table.insert(mnu, {
				text = VFLI.i18n("Open copy paste: ".. desc.number);
				OnClick = function()
					VFL.poptree:Release();
					EditScriptDialog(nil, desc.number);
				end;
			});
		end);
		
		if not desc.ts then desc.ts = "None"; end
		local ts = "false";
		if desc.ts then ts = "true"; end
		if desc.ts == "None" then ts = "false"; end
		if not desc.color then desc.color = {r=1,g=1,b=1,a=1}; end
		
		local channel = "false"; if desc.channel then channel = "true"; end
		local fading = "0"; if desc.fading then fading = "1"; end

		------------------ On frame creation
		local createCode = [[
local btn = VFLUI.AcquireFrame("ChatFrame", ]] .. desc.number .. [[);
if btn then
	VFLUI.StdSetParent(btn, ]] .. RDXUI.ResolveFrameReference(desc.owner) .. [[);
	btn:SetPoint(]] .. RDXUI.AnchorCodeFromDescriptor(desc.anchor) .. [[);
	btn:SetWidth(]] .. desc.w .. [[); btn:SetHeight(]] .. desc.h .. [[);
	--if ]] .. ts .. [[ then
		btn.SetMsg(btn, "]] .. desc.ts .. [[", ]] .. Serialize(desc.color) .. [[, ]] .. channel .. [[);
	--end
	btn:SetFading(]] .. fading .. [[);
	SetChatWindowSize(btn:GetID(), ]] .. desc.font.size .. [[);
	]];
	createCode = createCode .. VFLUI.GenerateSetFontCode("btn", desc.font, nil, true);
	createCode = createCode .. [[
	frame.]] .. objname .. [[ = btn;
else
	RDX.printW("ChatFrame]] .. desc.number .. [[ is not available or already acquired");
end
]];
		state:Attach(state:Slot("EmitCreate"), true, function(code) code:AppendCode(createCode); end);

		------------------ On frame destruction.
		local destroyCode = [[
local btn = frame.]] .. objname .. [[;
if btn then btn:Destroy(); end
frame.]] .. objname .. [[ = nil;
]];
		state:Attach(state:Slot("EmitDestroy"), true, function(code) code:AppendCode(destroyCode); end);

		return true;
	end;
	UIFromDescriptor = function(desc, parent, state)
		local ui = VFLUI.CompoundFrame:new(parent);

		-- Name/width/height
		local ed_name, ed_width, ed_height = RDXUI.GenNameWidthHeightPortion(ui, desc, state);

		-- Owner
		local owner = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Owner"), state, "Subframe_");
		if desc and desc.owner then owner:SetSelection(desc.owner); end

		-- Anchor
		local anchor = RDXUI.UnitFrameAnchorSelector:new(ui); anchor:Show();
		anchor:SetAFArray(RDXUI.ComposeAnchorList(state));
		if desc and desc.anchor then anchor:SetAnchorInfo(desc.anchor); end
		ui:InsertFrame(anchor);
		
		local er = VFLUI.EmbedRight(ui, VFLI.i18n("ChatFrame number :"));
		local dd_number = VFLUI.Dropdown:new(er, RDXUI.NumberListSelectionFunc);
		dd_number:SetWidth(150); dd_number:Show();
		if desc and desc.number then
			dd_number:SetSelection(desc.number);
		else
			dd_number:SetSelection("1");
		end
		er:EmbedChild(dd_number); er:Show();
		ui:InsertFrame(er);
		
		local er_ts = VFLUI.EmbedRight(ui, VFLI.i18n("Timestamp type :"));
		local dd_ts = VFLUI.Dropdown:new(er_ts, VFL.ASDateListSelectionFunc);
		dd_ts:SetWidth(150); dd_ts:Show();
		if desc and desc.ts then
			dd_ts:SetSelection(desc.ts);
		else
			dd_ts:SetSelection("None");
		end
		er_ts:EmbedChild(dd_ts); er_ts:Show();
		ui:InsertFrame(er_ts);
		
		local color = RDXUI.GenerateColorSwatch(ui, VFLI.i18n("Timestamp color :"));
		if desc and desc.color then color:SetColor(VFL.explodeRGBA(desc.color)); end
		
		local chk_channel = VFLUI.Checkbox:new(ui); chk_channel:Show();
		chk_channel:SetText(VFLI.i18n("Minimize channel name"));
		if desc and desc.channel then chk_channel:SetChecked(true); else chk_channel:SetChecked(); end
		ui:InsertFrame(chk_channel);
		
		local er_font = VFLUI.EmbedRight(ui, VFLI.i18n("Font"));
		local fontsel = VFLUI.MakeFontSelectButton(er_font, desc.font); fontsel:Show();
		er_font:EmbedChild(fontsel); er_font:Show();
		ui:InsertFrame(er_font);
		
		local chk_fading = VFLUI.Checkbox:new(ui); chk_fading:Show();
		chk_fading:SetText(VFLI.i18n("Fading"));
		if desc and desc.fading then chk_fading:SetChecked(true); else chk_fading:SetChecked(); end
		ui:InsertFrame(chk_fading);
		
		function ui:GetDescriptor()
			return { 
				feature = "chatframe"; version = 1;
				name = ed_name.editBox:GetText();
				owner = owner:GetSelection();
				w = ed_width:GetSelection();
				h = ed_height:GetSelection();
				anchor = anchor:GetAnchorInfo();
				number = dd_number:GetSelection();
				ts = dd_ts:GetSelection();
				color = color:GetColor();
				channel = chk_channel:GetChecked();
				font = fontsel:GetSelectedFont();
				fading = chk_fading:GetChecked();
			};
		end

		return ui;
	end;
	CreateDescriptor = function()
		return { 
			feature = "chatframe"; version = 1; 
			name = "cf1", owner = "decor";
			w = 140; h = 20;
			anchor = { lp = "TOPLEFT", af = "Base", rp = "TOPLEFT", dx = 0, dy = 0};
			number = "1";
			ts = "None";
			color = {r=1,g=1,b=1,a=1};
			font = VFL.copy(Fonts.Default);
		};
	end;
});

-----------------------------------------------
-- ChatFrame editbox
-----------------------------------------------

--ChatEdit_OnHide

VFLUI.CreateFramePool("ChatFrameEditBox", 
	function(pool, x) -- on released
		if (not x) then return; end
		x:Hide();
		--VFLUI._CleanupLayoutFrame(x);
	end,
	function(_, key) -- on fallback
		local f = nil;
		--if key > 0 and key < 8 then
			f = _G["ChatFrame1EditBox"];
			-- "ChatFrame2EditBox"
			-- "ChatFrame3EditBox"
		--end
		return f;
	end, 
	function(_, f) -- on acquired
		--f:Show();
		f:ClearAllPoints();
	end,
"key");

RDX.RegisterFeature({
	name = "chatframeeditbox";
	version = 1;
	title = VFLI.i18n("ChatFrame EditBox");
	category = VFLI.i18n("Complexes");
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("Base") then return nil; end
		return true;
	end;
	ExposeFeature = function(desc, state, errs)
		if not desc then VFL.AddError(errs, VFLI.i18n("Missing descriptor.")); return nil; end
		if desc.owner == "Base" then desc.owner = "decor"; end
		local flg = true;
		--flg = flg and RDXUI.UFFrameCheck_Proto("Frame_", desc, state, errs);
		flg = flg and RDXUI.UFAnchorCheck(desc.anchor, state, errs);
		flg = flg and RDXUI.UFOwnerCheck(desc.owner, state, errs);
		if flg then state:AddSlot("Frame_cfeditbox"); end
		return flg;
	end;
	ApplyFeature = function(desc, state)
		local objname = "Frame_cfeditbox";
		if not desc.w then desc.w = 300; end
		
		local ak = "true"; if desc.ak then ak = "false"; end
		local hb = "false"; if desc.hb then hb = "true"; end
		
		------------------ On frame creation
		local createCode = [[
local btn = VFLUI.AcquireFrame("ChatFrameEditBox", "EditBox");
if btn then
	VFLUI.StdSetParent(btn, ]] .. RDXUI.ResolveFrameReference(desc.owner) .. [[);
	btn:SetPoint(]] .. RDXUI.AnchorCodeFromDescriptor(desc.anchor) .. [[);
	btn:SetWidth(]] .. desc.w .. [[);
	
	
	btn:SetAltArrowKeyMode(]] .. ak .. [[);
	
	if ]] .. hb .. [[ then
		local left, mid, right, l2, m2, r2 = select(6, btn:GetRegions());
		left:Hide();
		mid:Hide();
		right:Hide();
		l2:SetTexture(nil);
		m2:SetTexture(nil);
		r2:SetTexture(nil);
	end
	btn:Show();
else
	RDX.printW("ChatFrame Edit Box is not available or already acquired");
end

frame.]] .. objname .. [[ = btn;
]];
		state:Attach(state:Slot("EmitCreate"), true, function(code) code:AppendCode(createCode); end);

		------------------ On frame destruction.
		local destroyCode = [[
local btn = frame.]] .. objname .. [[;
if btn then
	local left, mid, right = select(6, btn:GetRegions());
	left:Show();
	mid:Show();
	right:Show();
	btn:Destroy();
end
frame.]] .. objname .. [[ = nil;
]];
		state:Attach(state:Slot("EmitDestroy"), true, function(code) code:AppendCode(destroyCode); end);

		return true;
	end;
	UIFromDescriptor = function(desc, parent, state)
		local ui = VFLUI.CompoundFrame:new(parent);

		-- Name/width/height
		--local ed_name, ed_width, ed_height = RDXUI.GenNameWidthHeightPortion(ui, desc, state);

		-- Owner
		local owner = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Owner"), state, "Subframe_");
		if desc and desc.owner then owner:SetSelection(desc.owner); end

		-- Anchor
		local anchor = RDXUI.UnitFrameAnchorSelector:new(ui); anchor:Show();
		anchor:SetAFArray(RDXUI.ComposeAnchorList(state));
		if desc and desc.anchor then anchor:SetAnchorInfo(desc.anchor); end
		ui:InsertFrame(anchor);
		
		local ed_width = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Width"), state, "StaticVar_");
		if desc and desc.w then ed_width:SetSelection(desc.w); end
		
		local chk_arrowkey = VFLUI.Checkbox:new(ui); chk_arrowkey:Show();
		chk_arrowkey:SetText(VFLI.i18n("Disable Alt arrow key"));
		if desc and desc.ak then chk_arrowkey:SetChecked(true); else chk_arrowkey:SetChecked(); end
		ui:InsertFrame(chk_arrowkey);
		
		local chk_hideborder = VFLUI.Checkbox:new(ui); chk_hideborder:Show();
		chk_hideborder:SetText(VFLI.i18n("Hide Border"));
		if desc and desc.hb then chk_hideborder:SetChecked(true); else chk_hideborder:SetChecked(); end
		ui:InsertFrame(chk_hideborder);
		
		function ui:GetDescriptor()
			local wa = VFL.clamp(tonumber(ed_width:GetSelection()), 200, 600);
			return { 
				feature = "chatframeeditbox"; version = 1;
				owner = owner:GetSelection();
				anchor = anchor:GetAnchorInfo();
				w = wa;
				ak = chk_arrowkey:GetChecked();
				hb = chk_hideborder:GetChecked();
			};
		end

		return ui;
	end;
	CreateDescriptor = function()
		return { 
			feature = "chatframeeditbox"; version = 1; 
			--name = "cf1";
			owner = "decor";
			w = 300; 
			--h = 20;
			anchor = { lp = "TOPLEFT", af = "Base", rp = "TOPLEFT", dx = 0, dy = 0};
		};
	end;
});

