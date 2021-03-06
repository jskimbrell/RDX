-- GameTooltip.lua
-- use to move the gametooltip

local usemouse, anchorx, anchory = nil, 0, 0;
local style = {};

local btn = VFLUI.Button:new();
btn:SetHeight(100); btn:SetWidth(100);
btn:SetText(VFLI.i18n("GameTooltip"));
btn:SetClampedToScreen(true);

function RDXDK.SetGameTooltipLocation(mb, x, y)
	if not x then x = 0; end
	if not y then y = 0; end
	usemouse, anchorx, anchory = mb, x, y;
	btn:ClearAllPoints();
	btn:SetPoint("BOTTOMLEFT", RDXParent, "BOTTOMLEFT", anchorx, anchory);
	btn:Hide();
end

-- move game tooltip
-- on desktop unlock
function RDXDK.SetUnlockGameTooltip()
	btn:ClearAllPoints();
	btn:SetPoint("BOTTOMLEFT", RDXParent, "BOTTOMLEFT", anchorx, anchory);
	btn:Show();
	btn:SetMovable(true);
	btn:SetScript("OnMouseDown", function(th) th:StartMoving(); end);
	btn:SetScript("OnMouseUp", function(th) th:StopMovingOrSizing(); anchorx,_,_,anchory = VFLUI.GetUniversalBoundary(btn); end);
end

-- on desktop lock
function RDXDK.SetLockGameTooltip()
	btn:SetMovable(nil);
	btn:SetScript("OnMouseDown", nil);
	btn:SetScript("OnMouseUp", nil);
	btn:Hide();
	return nil, anchorx, anchory;
end

-- Add option to disable tooltip
-- option dgr managed in globalSettings
RDXEvents:Bind("INIT_VARIABLES_LOADED", nil, function()
	local opt =  RDXU.disablebliz;
	if opt and opt.toolposition then
		hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
			if usemouse then
				GameTooltip:SetOwner(parent, "ANCHOR_CURSOR");
			else
				GameTooltip:SetOwner(parent, "ANCHOR_NONE");
				GameTooltip:SetPoint("CENTER", btn, "CENTER");
			end
		end);
	end
	if opt and opt.tooltipunit then
		-- hide the game tooltip for unit only
		GameTooltip:SetScript("OnTooltipSetUnit",function()
			if GameTooltipStatusBar then
				GameTooltip:Hide();
			end
		end);
	end
end);