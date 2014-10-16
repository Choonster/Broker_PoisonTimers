local ADDON_NAME, ns = ...

---------------
-- Constants --
---------------
local BPT_VERSION = tonumber(GetAddOnMetadata(ADDON_NAME, "Version")) or 2.0
local LDB = LibStub("LibDataBroker-1.1")
local POISON_ICON = "Interface\\Icons\\Trade_BrewPoison.blp"
local NO_ICON = "Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Opaque.blp"
local NO_WEAPON_STRING = "No Weapon"
local NO_POISON_STRING = "No Poison"
local FORMAT_STRING = "%s %s"

local POISON_ICONS = {
	["Instant Poison"]		= "Interface\\Icons\\Ability_Poisons",
	["Deadly Poison"]		= "Interface\\Icons\\Ability_Rogue_DualWeild",
	["Crippling Poison"]	= "Interface\\Icons\\Ability_PoisonSting",
	["Mind-Numbing Poison"]	= "Interface\\Icons\\Spell_Nature_NullifyDisease",
	["Wound Poison"]		= "Interface\\Icons\\INV_Misc_Herb_16",
}

------------------
-- Data Objects --
------------------
ns.mainhand = LDB:NewDataObject("PoisonTimers Main Hand", {type = "data source", text = "", timeLeft = 0, icon = POISON_ICON, slotname = "Main Hand", key = "mainhand"})
ns.offhand  = LDB:NewDataObject("PoisonTimers Off Hand",  {type = "data source", text = "", timeLeft = 0, icon = POISON_ICON, slotname = "Off Hand", key = "offhand"})

local f = CreateFrame("Frame")

local function GetTimerText(dataObj)
	if not dataObj then return "Error: Missing dataObj" end
	
	local timeleft = dataObj.timeLeft
	local icon = dataObj.poisonicon
	
	local settings = BPT_DB[dataObj.key]
	local showicon, str = settings.showicon, settings.string
		
	return strjoin("", showicon and "|T".. icon ..":15|t" or "", timeleft < 0 and "|cffff0000" or "", date(str, timeleft > 0 and timeleft or 0), timeleft < 0 and "|r" or "")
end

f:SetScript("OnUpdate", function(self, elapsed)
	ns.mainhand.timeLeft = ns.mainhand.timeLeft - elapsed
	ns.mainhand.text = GetTimerText(ns.mainhand)

	ns.offhand.timeLeft = ns.offhand.timeLeft - elapsed
	ns.offhand.text = GetTimerText(ns.offhand)
end)

------
-- The code below here was adapated from Tomber's Raven, which adapted it from ccknight's PitBull Unit Frames
------

local bufftooltip; -- The tooltip we use to scan our temporary weapon enchants

-- Initialize tooltip to be used for determining weapon buffs
-- This code is based on the Pitbull implementation
function f:InitialiseBuffTooltip()
	bufftooltip = CreateFrame("GameTooltip", nil, UIParent)
	bufftooltip:SetOwner(UIParent, "ANCHOR_NONE")
	bufftooltip.lines = {}
	local fs = bufftooltip:CreateFontString()
	fs:SetFontObject(GameFontNormal)
	for i = 1, 30 do
		local ls = bufftooltip:CreateFontString()
		ls:SetFontObject(GameFontNormal)
		bufftooltip:AddFontStrings(ls, fs)
		bufftooltip.lines[i] = ls
	end
end

-- No easy way to get this info, so scan item slot info for mainhand and offhand weapons using a tooltip
-- Weapon buffs are usually formatted in tooltips as name strings followed by remaining time in parentheses
-- This routine scans the tooltip for the first line that is in this format and extracts the weapon buff name without rank or time
local function GetWeaponBuff(weaponSlot)
	bufftooltip:ClearLines()
	if not bufftooltip:IsOwned(UIParent) then bufftooltip:SetOwner(UIParent, "ANCHOR_NONE") end
	bufftooltip:SetInventoryItem("player", weaponSlot)
	for i = 1, 30 do
		local text = bufftooltip.lines[i]:GetText()
		if text then
			local name = text:match("^(.+) %(%d+ [^$)]+%)$") -- extract up to left paren if match weapon buff format
			if name then
				name = (name:match("^(.*) %d+$")) or name -- remove any trailing numbers
				return name
			end
		else
			break
		end
	end
	return nil
end

-----
-- End of Raven code
-----

local function UpdateWeapon(dataObj, invSlot)
	dataObj.itemlink = GetInventoryItemLink("player", invSlot) or NO_WEAPON_STRING
	dataObj.itemicon = GetInventoryItemTexture("player", invSlot) or NO_ICON
	dataObj.poisonname = GetWeaponBuff(invSlot) or NO_POISON_STRING
	dataObj.poisonicon = POISON_ICONS[dataObj.poisonname] or NO_ICON
	dataObj.text = GetTimerText(dataObj)
end

local function UpdateWeapons()
	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()

	if hasMainHandEnchant then
		ns.mainhand.timeLeft = mainHandExpiration / 1000
	else
		ns.mainhand.timeLeft = 0
	end
	
	if hasOffHandEnchant then
		ns.offhand.timeLeft = offHandExpiration / 1000
	else
		ns.offhand.timeLeft = 0
	end
	
	UpdateWeapon(ns.mainhand, INVSLOT_MAINHAND)
	UpdateWeapon(ns.offhand, INVSLOT_OFFHAND)
end

local function SetDefaults()
	BPT_DB = BPT_DB or {
		version = BPT_VERSION,
		mainhand = {string = "M: %M:%S", showicon = false},
		offhand  = {string = "O: %M:%S", showicon = false},
	}
	
	if not BPT_DB.version or BPT_DB.version < 1.2 then -- Update the DB to the 1.2 format
		local mainhand = BPT_DB.mainhand.prefix .." ".. BPT_DB.mainhand.timer
		local offhand = BPT_DB.offhand.prefix .." ".. BPT_DB.offhand.timer
		local thrown = BPT_DB.thrown.prefix .." ".. BPT_DB.thrown.timer
		BPT_DB = {
			version = 1.2,
			mainhand = mainhand,
			offhand = offhand,
			thrown = thrown,
		}
	end
	
	if BPT_DB.version < 1.3 then -- Update the DB to the 1.3 format
		local mainhand = BPT_DB.mainhand
		local offhand = BPT_DB.offhand
		local thrown = BPT_DB.thrown
		BPT_DB = {
			version = 1.3,
			mainhand = {string = mainhand, showicon = false},
			offhand = {string = offhand, showicon = false},
			thrown = {string = thrown, showicon = false},
		}
	end
	
	if BPT_DB.version < 2.0 then
		BPT_DB.thrown = nil
	end
end

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")

f:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

function f:PLAYER_ENTERING_WORLD()
	SetDefaults()
	self:InitialiseBuffTooltip()
	UpdateWeapons()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD") -- We only care about this when logging in, so no need to watch it after the initial fire.
end

function f:UNIT_INVENTORY_CHANGED(unit)
	UpdateWeapons()
end

--------------
-- Tooltips --
--------------

-- Pass GameTooltip as tooltip.
-- Pass ns.mainhand or ns.offhand as dataObj
local function OnTooltipShow(tooltip, dataObj)
	tooltip:AddDoubleLine("PoisonTimers", dataObj.slotname)
	tooltip:AddDoubleLine("|T".. dataObj.itemicon ..":25|t", dataObj.itemlink, 1,1,1, 1,1,1)
	tooltip:AddDoubleLine("|T".. dataObj.poisonicon ..":25|t", dataObj.poisonname, 1,1,1, 1,1,1)
end

local function OnEnter(self, dataObj)
	UpdateWeapons()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	OnTooltipShow(GameTooltip, dataObj)
	GameTooltip:Show()
end

function ns.mainhand:OnEnter()
	OnEnter(self, ns.mainhand)
end

function ns.mainhand:OnLeave()
	GameTooltip:Hide()
end

function ns.offhand:OnEnter()
	OnEnter(self, ns.offhand)
end

function ns.offhand:OnLeave()
	GameTooltip:Hide()
end

-------------------
-- Slash Command --
-------------------

local Print, TPrint
do
	local colours = {
		red = "|cffff0000",
		cyan = "|cff33ff99",
		green = "|cff00ff00",
		blue = "|cff0000ff",
		gold = "|cffffd800",
		silver = "|cffb0b0b0",
		copper = "|cff9a4f29",
	}

	local temp = {}
	local function colourSub(...)
		local numArgs = select("#", ...)
		for i = 1, numArgs do
			str = select(i, ...)
			str = type(str) == "string" and str or tostring(str)
			temp[i] = str:gsub("%$(%a+)%$", colours)
		end
		
		return unpack(temp, 1, numArgs)
	end
	
	local prefix = "$cyan$".. ADDON_NAME ..":|r"
	
	function Print(...)
		print(colourSub(prefix, ...))
	end
	
	function TPrint(num, ...)
		print(colourSub(format("%".. 4 * num .."s", ""), ...))
	end
end

local function IsValidName(name)
	return name == "mainhand" or name == "offhand"
end

SLASH_BROKER_POISONTIMERS1, SLASH_BROKER_POISONTIMERS2, SLASH_BROKER_POISONTIMERS3 = "/brokerpoisontimers", "/poisontimers", "/bpt"

SlashCmdList.BROKER_POISONTIMERS = function(input)
	local cmd, objectname, setting = input:trim():match("^(%a+)%s+(%a+)%s+(.+)$")
	cmd, objectname = (cmd or ""):lower(), (objectname or ""):lower()
	
	if cmd == "string" and IsValidName(objectname) then
		BPT_DB[objectname].string = setting
		Print(("Timer string for %s set to %q"):format(objectname, setting))
	elseif cmd == "showicon" and IsValidName(objectname) then
		BPT_DB[objectname].showicon = (setting == "enable")
		Print(("Poison icon for %s %s."):format(objectname, setting == "enable" and "$green$enabled" or "$red$disabled"))
	else
		Print("Slash Command Usage.")
		TPrint(1, ("$red$%s|r or $red$%s|r or $red$%s command mainhand||offhand setting|r"):format(SLASH_BROKER_POISONTIMERS1, SLASH_BROKER_POISONTIMERS2, SLASH_BROKER_POISONTIMERS3))
		TPrint(2, "$red$showicon mainhand||offhand enable||disable|r -- Enable/disable showing of the poison/imbue icon next to the timer.")
		TPrint(2, "$red$string mainhand||offhand setting|r -- Changes the time format of the specified timer to $red$setting|r. $red$setting|r can contain all characters (including spaces).")
		TPrint(3, "$red$%M|r and $red$%S|r will be replaced with the minutes and seconds remaining, respectively. To display a percent sign in the format, you must use $red$%%|r. The default time format is \"$red$X: %M:%S|r\" (where $red$X|r is $red$M|r, $red$O|r or $red$T|r).")
		TPrint(3, "Several other tokens can be used in the time format, but only the minutes/seconds have meaningful values. The other tokens can be found at the link to \"strftime\" at $green$http://www.wowpedia.org/API_date|r.")
		TPrint(3, "If you get a Lua error telling you that the \"format is too long\", it actually means the function used to display the timers doesn't support one of the tokens you used.")
	end
end