-- OpenRDX
-- Sigg / Rashgarroth EU

local tysl = {};

function RDXDB.GetSymLinkTarget(data)
	if not data or not data.class then return; end
	local sl = tysl[data.class];
	if not sl then return; end
	return sl.GetTargetPath(data);
end

function RDXDB.RegisterSymLinkClass(tbl)
	local name = tbl.name;
	if not name then VFL.print(VFLI.i18n("|cFFFF0000[RDX]|r Info : Attempt to register an anonymous SymLink type.")); return; end
	if tysl[name] then VFL.print(VFLI.i18n("|cFFFF0000[RDX]|r Info : Attempt to register duplicate SymLink type ") .. name .. "."); return; end
	tysl[name] = tbl;
end

local function GetSymLinkClassByName(n)
	if not n then return nil; end
	return tysl[n];
end


-- The "SymLink" object type
local dlg = nil;
local function EditSymlink(parent, path, md)
	if dlg then
		RDX.printI(VFLI.i18n("A symlink editor is already open. Please close it first.")); return;
	end
	if (not path) or (not md) then return; end
	-- Create the dialog
	dlg = VFLUI.Window:new(parent);
	VFLUI.Window.SetDefaultFraming(dlg, 22);
	dlg:SetTitleColor(0,0,.6);
	dlg:SetBackdrop(VFLUI.BlackDialogBackdrop);
	dlg:SetPoint("CENTER", VFLParent, "CENTER");
	dlg:SetWidth(335); dlg:SetHeight(320);
	dlg:SetText(VFLI.i18n("Edit Symlink: ") .. path);
	VFLUI.Window.StdMove(dlg, dlg:GetTitleBar());
	if RDXPM.Ismanaged("symlink_editor") then RDXPM.RestoreLayout(dlg, "symlink_editor"); end

	local slsel = RDXDB.SymLinkFinder:new(dlg:GetClientArea());
	slsel:SetPoint("TOPLEFT", dlg:GetClientArea(), "TOPLEFT");
	slsel:SetWidth(310); slsel:SetHeight(260);

	if md.data and type(md.data) == "table" then slsel:SetDescriptor(md.data); end
	slsel.isLayoutRoot = true;
	if slsel.DialogOnLayout then slsel:DialogOnLayout(); end
	slsel:Show();
	-- Show the editor	
	dlg:Show(.2, true);

	---------- Destruction
	local esch = function() 
		dlg:Hide(.2, true);
		VFLT.ZMSchedule(.25, function()
			RDXPM.StoreLayout(dlg, "symlink_editor");
			dlg:Destroy(); dlg = nil;
		end);
	end
	VFL.AddEscapeHandler(esch);
	local btnClose = VFLUI.CloseButton:new(dlg);
	dlg:AddButton(btnClose);
	btnClose:SetScript("OnClick", function() VFL.EscapeTo(esch); end);

	local btnOK = VFLUI.OKButton:new(dlg);
	btnOK:SetText(VFLI.i18n("OK")); btnOK:SetHeight(25); btnOK:SetWidth(75);
	btnOK:SetPoint("BOTTOMRIGHT", dlg:GetClientArea(), "BOTTOMRIGHT");
	btnOK:Show();
	btnOK:SetScript("OnClick", function()
		md.data = slsel:GetDescriptor();
		VFL.EscapeTo(esch);
		local sl = tysl[md.data.class];
		if sl and sl.Unregister then sl.Unregister(path); end
		if sl and sl.Register then sl.Register(path); end
		RDXDB.NotifyUpdate(path);
	end);

	dlg.Destroy = VFL.hook(function(s)
		btnOK:Destroy(); btnOK = nil;
		slsel:Destroy(); slsel = nil;
		dlg = nil;
	end, dlg.Destroy);
end

--- Open an editor for the given symlink
function RDXDB.EditSymLink(path, parent)
	local data = RDXDB._AccessPathRaw(RDXDB.ParsePath(path));
	if not data then return; end
	EditSymlink(parent, path, data);
end

--- Repoint the given symlink at another destination.
function RDXDB.SetSymLinkTarget(linkPath, targetPath)
	-- Sanity check
	--local data = RDXDB._AccessPathRaw(RDXDB.ParsePath(linkPath));
	--if (not data) or (data.ty ~= "SymLink") then return; end
	-- Update the link
	--data.data = targetPath;
	-- Notify of update
	--RDXDB.NotifyUpdate(linkPath);
	VFL.print("DEPRECATED FUNCTION RDXDB.SetSymLinkTarget");
end

RDXDB.RegisterObjectType({
	name = "SymLink";
	version = 3;
	VersionMismatch = function(md)
		-- code update version 1 and version 2 to version 3;
		md.version = 3;
		-- save md.data
		local tmpdata = md.data;
		if type(tmpdata) == "string" then 
			md.data = {class = "simple"; targetpath = tmpdata;};
			tmpdata = nil;
		end
		return true;
	end,
	New = function(path, md) md.version = 3; md.data = {class = "simple"; targetpath = ""}; end;
	GenerateBrowserMenu = function(mnu, path, md, dlg)
		table.insert(mnu, {
			text = VFLI.i18n("Edit...");
			OnClick = function()
				VFL.poptree:Release();
				EditSymlink(dlg, path, md);
			end;
		});
	end;
});

RDXDB.SymLinkFinder = {};
function RDXDB.SymLinkFinder:new(parent)
	local self = VFLUI.SelectEmbed:new(parent, 150, function()
		local qq = {};
		for k,v in pairs(tysl) do table.insert(qq, {text = v.title, value = v}); end
		return qq;
	end, function(ctl, desc)
		local cls = GetSymLinkClassByName(desc.class);
		if cls then
			return cls.GetUI(ctl, desc), cls.title, cls;
		end
	end);
	self:SetText(VFLI.i18n("Set class:"));
	return self;
end

RDXDB.RegisterSymLinkClass({
	name = "simple";
	title = "simple";
	GetTargetPath = function(data)
		return data.targetpath;
	end;
	Unregister = function(path)
		--VFL.print("UNREGISTER " .. path);
		VFLEvents:Unbind("symlink_" .. path);
	end;
	GetUI = function(parent, desc)
		local ui = VFLUI.CompoundFrame:new(parent);
		
		local ff = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff:SetLabel(VFLI.i18n("Link target"));
		if desc and desc.targetpath then ff:SetPath(desc.targetpath); end
		ff:Show();
		ui:InsertFrame(ff);

		ui.GetDescriptor = function(x)
			return {class = "simple", targetpath = ff:GetPath()};
		end;

		ui.Destroy = VFL.hook(function(s) s.GetDescriptor = nil; end, ui.Destroy);

		return ui;
	end;
});

RDXDB.RegisterSymLinkClass({
	name = "talent";
	title = "talent";
	GetTargetPath = function(data)
		return data["talentpath_" .. GetActiveTalentGroup()];
	end;
	Register = function(path)
		--VFL.print("REGISTER " .. path);
		VFLEvents:Bind("PLAYER_TALENT_UPDATE", nil, function() RDXDB.NotifyUpdate(path); end, "symlink_" .. path);
	end;
	Unregister = function(path)
		--VFL.print("UNREGISTER " .. path);
		VFLEvents:Unbind("symlink_" .. path);
	end;
	GetUI = function(parent, desc)
		local ui = VFLUI.CompoundFrame:new(parent);
		
		local ff = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff:SetLabel(VFLI.i18n("Talent 1"));
		if desc and desc.talentpath_1 then ff:SetPath(desc.talentpath_1); end
		ff:Show();
		ui:InsertFrame(ff);
		
		local ff2 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff2:SetLabel(VFLI.i18n("Talent 2"));
		if desc and desc.talentpath_2 then ff2:SetPath(desc.talentpath_2); end
		ff2:Show();
		ui:InsertFrame(ff2);

		ui.GetDescriptor = function(x)
			return {class = "talent", talentpath_1 = ff:GetPath(), talentpath_2 = ff2:GetPath()};
		end;

		ui.Destroy = VFL.hook(function(s) s.GetDescriptor = nil; end, ui.Destroy);

		return ui;
	end;
});

RDXDB.RegisterSymLinkClass({
	name = "class";
	title = "class";
	GetTargetPath = function(data)
		return data["targetpath_" .. RDXMD.GetClassID(select(2, UnitClass("PLAYER")))];
	end;
	Unregister = function(path)
		--VFL.print("UNREGISTER " .. path);
		VFLEvents:Unbind("symlink_" .. path);
	end;
	GetUI = function(parent, desc)
		local ui = VFLUI.CompoundFrame:new(parent);
		
		local ff = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff:SetLabel(VFLI.i18n("PRIEST"));
		if desc and desc.targetpath_1 then ff:SetPath(desc.targetpath_1); end
		ff:Show();
		ui:InsertFrame(ff);
		
		local ff2 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff2:SetLabel(VFLI.i18n("DRUID"));
		if desc and desc.targetpath_2 then ff2:SetPath(desc.targetpath_2); end
		ff2:Show();
		ui:InsertFrame(ff2);
		
		local ff3 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff3:SetLabel(VFLI.i18n("PALADIN"));
		if desc and desc.targetpath_3 then ff3:SetPath(desc.targetpath_3); end
		ff3:Show();
		ui:InsertFrame(ff3);
		
		local ff4 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff4:SetLabel(VFLI.i18n("SHAMAN"));
		if desc and desc.targetpath_4 then ff4:SetPath(desc.targetpath_4); end
		ff4:Show();
		ui:InsertFrame(ff4);
		
		local ff5 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff5:SetLabel(VFLI.i18n("WARRIOR"));
		if desc and desc.targetpath_5 then ff5:SetPath(desc.targetpath_5); end
		ff5:Show();
		ui:InsertFrame(ff5);
		
		local ff6 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff6:SetLabel(VFLI.i18n("WARLOCK"));
		if desc and desc.targetpath_6 then ff6:SetPath(desc.targetpath_6); end
		ff6:Show();
		ui:InsertFrame(ff6);
		
		local ff7 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff7:SetLabel(VFLI.i18n("MAGE"));
		if desc and desc.targetpath_7 then ff7:SetPath(desc.targetpath_7); end
		ff7:Show();
		ui:InsertFrame(ff7);
		
		local ff8 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff8:SetLabel(VFLI.i18n("ROGUE"));
		if desc and desc.targetpath_8 then ff8:SetPath(desc.targetpath_8); end
		ff8:Show();
		ui:InsertFrame(ff8);
		
		local ff9 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff9:SetLabel(VFLI.i18n("HUNTER"));
		if desc and desc.targetpath_9 then ff9:SetPath(desc.targetpath_9); end
		ff9:Show();
		ui:InsertFrame(ff9);
		
		local ff10 = RDXDB.ObjectFinder:new(parent, function(p,f,md) return (md and type(md) == "table"); end);
		ff10:SetLabel(VFLI.i18n("DEATHKNIGHT"));
		if desc and desc.targetpath_10 then ff10:SetPath(desc.targetpath_10); end
		ff10:Show();
		ui:InsertFrame(ff10);

		ui.GetDescriptor = function(x)
			return {
				class = "class", 
				targetpath_1 = ff:GetPath(),
				targetpath_2 = ff2:GetPath(),
				targetpath_3 = ff3:GetPath(),
				targetpath_4 = ff4:GetPath(),
				targetpath_5 = ff5:GetPath(),
				targetpath_6 = ff6:GetPath(),
				targetpath_7 = ff7:GetPath(),
				targetpath_8 = ff8:GetPath(),
				targetpath_9 = ff9:GetPath(),
				targetpath_10 = ff10:GetPath(),
			};
		end;

		ui.Destroy = VFL.hook(function(s) s.GetDescriptor = nil; end, ui.Destroy);

		return ui;
	end;
});

local _objectsadd = {
	{ text = "AuraFilter" },
	{ text = "MouseBindings" },
	{ text = "UnitFrameType" },
};
local function ObjectsTypesDropdownFunction() return _objectsadd; end

RDXDB.RegisterSymLinkClass({
	name = "name&realm";
	title = "name&realm";
	GetTargetPath = function(data)
		if not data.pkg or not data.prefixfile or not data.ty then return nil; end
		if data.pkg ~= "default" then
			RDXDB.CreateObject(data.pkg, data.prefixfile .. RDX.pspace, data.ty);
		end
		return data.pkg .. ":" .. data.prefixfile .. RDX.pspace;
	end;
	Unregister = function(path)
		VFLEvents:Unbind("symlink_" .. path);
	end;
	GetUI = function(parent, desc)
		local ui = VFLUI.CompoundFrame:new(parent);
		
		local ed_pkg = VFLUI.LabeledEdit:new(ui, 150); ed_pkg:Show();
		ed_pkg:SetText(VFLI.i18n("Package"));
		if desc and desc.pkg then ed_pkg.editBox:SetText(desc.pkg); end
		ui:InsertFrame(ed_pkg);
		
		local ed_prefixfile = VFLUI.LabeledEdit:new(ui, 150); ed_prefixfile:Show();
		ed_prefixfile:SetText(VFLI.i18n("Prefix"));
		if desc and desc.prefixfile then ed_prefixfile.editBox:SetText(desc.prefixfile); end
		ui:InsertFrame(ed_prefixfile);
		
		local er = VFLUI.EmbedRight(ui, VFLI.i18n("Object Type:"));
		local dd_objectType = VFLUI.Dropdown:new(er, ObjectsTypesDropdownFunction);
		dd_objectType:SetWidth(150); dd_objectType:Show();
		if desc and desc.ty then 
			dd_objectType:SetSelection(desc.ty); 
		else
			dd_objectType:SetSelection("AuraFilter");
		end
		er:EmbedChild(dd_objectType); er:Show();
		ui:InsertFrame(er);
		
		ui.GetDescriptor = function(x)
			return {
				class = "name&realm", 
				pkg = ed_pkg.editBox:GetText(),
				prefixfile = ed_prefixfile.editBox:GetText(),
				ty = dd_objectType:GetSelection();
			};
		end;

		ui.Destroy = VFL.hook(function(s) s.GetDescriptor = nil; end, ui.Destroy);

		return ui;
	end;
});


-----------------------------------------
-- Register event for symlink
-----------------------------------------

RDXDBEvents:Bind("OBJECT_DELETED", nil, function(pkg, file, md)
	if md and md.ty == "SymLink" then
		local path = RDXDB.MakePath(pkg,file);
		if md.data and type(md.data) == "table" then
			local sl = tysl[md.data.class];
			if not sl then return; end
			if sl.Unregister then sl.Unregister(path); end
		end
	end
end);
RDXDBEvents:Bind("OBJECT_MOVED", nil, function(pkg, file, newpkg, newfile, md)
	if md and md.ty == "SymLink" then
		local path = RDXDB.MakePath(pkg,file);
		local path2 =  RDXDB.MakePath(newpkg,newfile);
		if md.data and type(md.data) == "table" then
			local sl = tysl[md.data.class];
			if not sl then return; end
			if sl.Unregister then sl.Unregister(path); end
			if sl.Register then sl.Register(path2); end
		end
	end
end);

-- run on UI load 
local function ApplyEvents()
	for pkgName,pkg in pairs(RDXData) do
		for objName,md in pairs(pkg) do
			if type(md) == "table" and md.ty == "SymLink" then
				if md.data and type(md.data) == "table" then
					local sl = tysl[md.data.class or "toto"];
					if not sl then return; end
					if sl.Register then sl.Register(pkgName .. ":" ..objName); end
				end
			end
		end
	end
end
RDXEvents:Bind("INIT_VARIABLES_LOADED", nil, function()
	ApplyEvents();
end);

