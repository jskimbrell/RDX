-- Portraits.lua
-- RDX - Raid Data Exchange
-- (C)2007 Raid Informatics
--
-- THIS FILE CONTAINS COPYRIGHTED MATERIAL SUBJECT TO THE TERMS OF A SEPARATE
-- LICENSE. UNLICENSED COPYING IS PROHIBITED.
--
-- Support for portraits on unit frames.

-- Modify by Joeba18

-- Global function to set a model to camera zero
function SetCameraZero(self) self:SetCamera(0); end
function SetCameraOne(self) self:SetCamera(1); end

local _types = {
	{ text = "SetCameraZero" },
	{ text = "SetCameraOne" },
};
local function _dd_cameratypes() return _types; end

----------- 3D Portrait object
RDX.RegisterFeature({
	name = "portrait_3d"; version = 1; multiple = true;
	title = VFLI.i18n("3D Portrait"); category = VFLI.i18n("Textures");
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("Base") then return nil; end
		return true;
	end;
	ExposeFeature = function(desc, state, errs)
		if desc.owner == "Base" then desc.owner = "decor"; end
		local flg = true;
		flg = flg and RDXUI.UFAnchorCheck(desc.anchor, state, errs);
		flg = flg and RDXUI.UFFrameCheck_Proto("Frame_", desc, state, errs);
		flg = flg and RDXUI.UFOwnerCheck(desc.owner, state, errs);
		if flg then 
			state:AddSlot("Frame_" .. desc.name);
		end
		return flg;
	end;
	ApplyFeature = function(desc, state)
		local objname = "Frame_" .. desc.name;
		local camera = "SetCameraZero";
		if desc and desc.cameraType then camera = desc.cameraType; end

		-- Creation/destruction
		local createCode = [[
local _f = VFLUI.AcquireFrame("PlayerModel");
VFLUI.StdSetParent(_f, ]] .. RDXUI.ResolveFrameReference(desc.owner) .. [[, ]] .. desc.flOffset .. [[);
_f:SetPoint(]] .. RDXUI.AnchorCodeFromDescriptor(desc.anchor) .. [[);
_f:SetWidth(]] .. desc.w .. [[); _f:SetHeight(]] .. desc.h .. [[);
_f:Show();
_f:SetScript("OnShow", ]].. camera ..[[);
frame.]] .. objname .. [[ = _f;
]];
		local destroyCode = [[
frame.]] .. objname .. [[:Destroy(); frame.]] .. objname .. [[=nil;
]];
		state:Attach(state:Slot("EmitCreate"), true, function(code) code:AppendCode(createCode); end);
		state:Attach(state:Slot("EmitDestroy"), true, function(code) code:AppendCode(destroyCode); end);

		-- Event hinting.
		local mux, mask = state:GetContainingWindowState():GetSlotValue("Multiplexer"), 0;
		mask = mux:GetPaintMask("PORTRAIT");
		mux:Event_UnitMask("UNIT_PORTRAIT_UPDATE", mask);
		mask = bit.bor(mask, 1);

		-- Painting
		local paintCode = [[
if band(paintmask, ]] .. mask .. [[) ~= 0 then
	frame.]] .. objname .. [[:SetUnit(uid);
	]].. camera ..[[(frame.]] .. objname .. [[);
end
if UnitIsVisible(uid) then 
	frame.]] .. objname .. [[:Show();
else
	frame.]] .. objname .. [[:Hide();
end
]];
		state:Attach("EmitPaint", true, function(code) code:AppendCode(paintCode); end);

		return true;
	end;
	UIFromDescriptor = function(desc, parent, state)
		local ui = VFLUI.CompoundFrame:new(parent);

		local ed_name, ed_width, ed_height = RDXUI.GenNameWidthHeightPortion(ui, desc, state);

		local owner = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Owner"), state, "Subframe_");
		if desc and desc.owner then owner:SetSelection(desc.owner); end

		local anchor = RDXUI.UnitFrameAnchorSelector:new(ui); anchor:Show();
		anchor:SetAFArray(RDXUI.ComposeAnchorList(state));
		if desc and desc.anchor then anchor:SetAnchorInfo(desc.anchor); end
		ui:InsertFrame(anchor);

		local ed_flOffset = VFLUI.LabeledEdit:new(ui, 50); ed_flOffset:Show();
		ed_flOffset:SetText(VFLI.i18n("FrameLevel offset"));
		if desc and desc.flOffset then ed_flOffset.editBox:SetText(desc.flOffset); end
		ui:InsertFrame(ed_flOffset);
		
		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Camera Type:"));
		local dd_cameraType = VFLUI.Dropdown:new(er, _dd_cameratypes);
		dd_cameraType:SetWidth(200); dd_cameraType:Show();
		if desc and desc.cameraType then 
			dd_cameraType:SetSelection(desc.cameraType); 
		else
			dd_cameraType:SetSelection("SetCameraZero");
		end
		er:EmbedChild(dd_cameraType); er:Show();
		ui:InsertFrame(er);

		function ui:GetDescriptor()
			local a = ed_flOffset.editBox:GetNumber(); if not a then a=0; end a = VFL.clamp(a, -2, 5);
			return { 
				feature = "portrait_3d"; version = 1;
				name = ed_name.editBox:GetText();
				w = ed_width:GetSelection();
				h = ed_height:GetSelection();
				owner = owner:GetSelection();
				anchor = anchor:GetAnchorInfo();
				flOffset = a;
				cameraType = dd_cameraType:GetSelection();
			};
		end

		return ui;
	end;
	CreateDescriptor = function()
		return { 
			feature = "portrait_3d"; version = 1; 
			name = "portrait3d"; owner = "decor";
			w = 30; h = 30; 
			anchor = {lp = "RIGHT", af = "Base", rp = "LEFT", dx = 0, dy = 0}; 
			flOffset = 0;
		};
	end;
});
