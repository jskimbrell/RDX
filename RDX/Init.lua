-- Init.lua
-- RDX - Raid Data Exchange
-- (C)2006 Bill Johnson
--
-- Initialization code.
--

local installer = nil;

--- Is RDX initialized?
-- @return TRUE iff all RDX initialization procedures are complete.
function RDX.InstallerDone()
	installer = true;
end

-- Preload: Called when RDX is finished loading, before saved variables and before modules.
local function Preload()
	RDX:Debug(2, "Init: Preload()");

	-- Player name
	local pn = string.lower(UnitName("player"));
	local rn = string.lower(GetRealmName());
	-- BUGFIX: Quash all non-alpha-numerics in realmname, replace with underscores
	local lc = GetLocale();
	if lc == "ruRU" or lc == "koKR" or lc == "zhCN" or lc == "zhTW"  then
		-- do nothing
	else
		pn = string.gsub(pn, "[^%w_]", "");
		rn = string.gsub(rn, "[^%w_]", "");
	end
	RDX.pn = pn;
	--rn = string.gsub(rn, "[ ]", "_");
	RDX.pspace = RDX.pn .. "_" .. rn;
	RDX.Initialized()

	-- Raise preload event, then destroy all bindings (preload never happens again)
	RDX:Debug(3, "DISPATCH INIT_PRELOAD");
	RDXEvents:Dispatch("INIT_PRELOAD");
	RDXEvents:DeleteKey("INIT_PRELOAD");
	
end

-- VariablesLoaded: Called on VARIABLES_LOADED, that is to say after ALL addons have been loaded.
local function VariablesLoaded()
	RDX:Debug(2, "Init: VariablesLoaded()");

	-- Session variables
	if not RDXSession then RDXSession = {}; end
	-- RDXG (Global session variables)
	if not RDXSession.global then RDXSession.global = {}; end
	RDXG = RDXSession.global;
	-- RDXU (User session variables)
	if not RDXSession[RDX.pspace] then RDXSession[RDX.pspace] = {}; end
	RDXU = RDXSession[RDX.pspace];
	
	RDX:Debug(3, "DISPATCH INIT_VARIABLES_LOADED");
	RDXEvents:Dispatch("INIT_VARIABLES_LOADED");
	RDXEvents:DeleteKey("INIT_VARIABLES_LOADED");
	
	RDX:Debug(3, "DISPATCH INIT_POST_VARIABLES_LOADED");
	RDXEvents:Dispatch("INIT_POST_VARIABLES_LOADED");
	RDXEvents:DeleteKey("INIT_POST_VARIABLES_LOADED");
	
	RDX:Debug(3, "DISPATCH INIT_DESKTOP");
	RDXEvents:Dispatch("INIT_DESKTOP");
	RDXEvents:DeleteKey("INIT_DESKTOP");
	
	VFLT.NextFrame(math.random(10000000), function()
		RDX:Debug(3, "DISPATCH INIT_SPELL");
		RDXEvents:Dispatch("INIT_SPELL");
		RDXEvents:DeleteKey("INIT_SPELL");
		RDX:Debug(3, "DISPATCH INIT_POST_DESKTOP");
		RDXEvents:Dispatch("INIT_POST_DESKTOP");
		RDXEvents:DeleteKey("INIT_POST_DESKTOP");
		--DesktopEvents:Dispatch("DESKTOP_UPDATE_BINDINGS");
	end);

	VFLT.ZMSchedule(4, function()
		RDX:Debug(3, "DISPATCH INIT_DEFERRED");
		RDXEvents:Dispatch("INIT_DEFERRED");
		RDXEvents:DeleteKey("INIT_DEFERRED");
		
		if not RDXG.hideLW and installer then
			RDX.NewLearnWizard(RDXG.learnNum);
		end
	
		-- Now init smooth features.
		--RDX.smooth = 0.2;
	end);
end

-- Bind initialization events DEPRECATED
WoWEvents:Bind("VARIABLES_LOADED", nil, VariablesLoaded);

------------------------------- Last function that runs should always be Preload() ------------------------------
Preload();
