local addon, ns = ...

local bufftooltip; -- The tooltip we use to scan our temporary weapon enchants
local f = CreateFrame("Frame")
local BPT_VERSION = tonumber(GetAddOnMetadata(addon, "Version"))
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
	["Earthliving"]			= "Interface\\Icons\\Spell_Shaman_UnleashWeapon_Life",
	["Flametongue"]			= "Interface\\Icons\\Spell_Shaman_UnleashWeapon_Flame",
	["Windfury"]			= "Interface\\Icons\\Spell_Shaman_UnleashWeapon_Wind",
	["Rockbiter"]			= "Interface\\Icons\\Spell_Shaman_UnleashWeapon_Earth",
}

--Create the data objects
ns.mainhand = LDB:NewDataObject("PoisonTimers Main Hand", {type = "data source", text = "", timeLeft = 0, icon = POISON_ICON, slotname = "Main Hand"})
ns.offhand  = LDB:NewDataObject("PoisonTimers Off Hand",  {type = "data source", text = "", timeLeft = 0, icon = POISON_ICON, slotname = "Off Hand"})
ns.thrown   = LDB:NewDataObject("PoisonTimers Thrown",    {type = "data source", text = "", timeLeft = 0, icon = POISON_ICON, slotname = "Thrown"})

LibStub("ChoonLib-1.0"):Embed(f, "PoisonTimers")

local function GetTimerText(objectname)
	if not objectname then return "Error: Missing objectname" end
	if not ns[objectname] then return "Error: Invalid objectname" end
	
	local timeleft = ns[objectname].timeLeft
	local showicon = BPT_DB[objectname].showicon
	local str = BPT_DB[objectname].string
	local icon = ns[objectname].poisonicon
	
	return strjoin("", showicon and "|T".. icon ..":15|t" or "", timeleft < 0 and "|cffff0000" or "", date(str, timeleft > 0 and timeleft or 0), timeleft < 0 and "|r" or "")
	
	--[[if ns[objectname].timeLeft > 0 then
		return date(BPT_DB[objectname], ns[objectname].timeLeft)
	else
		return date("|cffff0000".. BPT_DB[objectname] .."|r", 0)
	end]]
end

f:SetScript("OnUpdate", function(self, elapsed)
	ns.mainhand.timeLeft = ns.mainhand.timeLeft - elapsed
	ns.mainhand.text = GetTimerText("mainhand")

	ns.offhand.timeLeft = ns.offhand.timeLeft - elapsed
	ns.offhand.text = GetTimerText("offhand")
	
	ns.thrown.timeLeft = ns.thrown.timeLeft - elapsed
	ns.thrown.text = GetTimerText("thrown")
end)

------
--The code below here was adapated from Tomber's Raven, which adapted it from ccknight's PitBull Unit Frames
------

-- Initialize tooltip to be used for determining weapon buffs
-- This code is based on the Pitbull implementation
function f:InitialiseBuffTooltip()
	bufftooltip = CreateFrame("GameTooltip", nil, UIParent)
	bufftooltip:SetOwner(UIParent, "ANCHOR_NONE")
	bufftooltip.lines = {}
	local fs = bufftooltip:CreateFontString()
	fs:SetFontObject(_G.GameFontNormal)
	for i = 1, 30 do
		local ls = bufftooltip:CreateFontString()
		ls:SetFontObject(_G.GameFontNormal)
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
--End of Raven code
-----


local function UpdateWeapons()
	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges, hasThrownEnchant, thrownExpiration, thrownCharges = GetWeaponEnchantInfo()

	if hasMainHandEnchant then
		ns.mainhand.timeLeft = mainHandExpiration / 1000
	else
		ns.mainhand.timeLeft = 0
	end
	print("mainhand", (mainHandExpiration or 0) / 1000, ns.mainhand.timeLeft)
	ns.mainhand.itemlink = GetInventoryItemLink("player", INVSLOT_MAINHAND) or NO_WEAPON_STRING
	ns.mainhand.itemicon = GetInventoryItemTexture("player", INVSLOT_MAINHAND) or NO_ICON
	ns.mainhand.poisonname = GetWeaponBuff(INVSLOT_MAINHAND) or NO_POISON_STRING
	ns.mainhand.poisonicon = POISON_ICONS[ns.mainhand.poisonname] or NO_ICON
	ns.mainhand.text = GetTimerText("mainhand")
	-----
	if hasOffHandEnchant then
		ns.offhand.timeLeft = offHandExpiration / 1000
	else
		ns.offhand.timeLeft = 0
	end
	print("offhand", (offHandExpiration or 0) / 1000, ns.offhand.timeLeft)
	ns.offhand.itemlink = GetInventoryItemLink("player", INVSLOT_OFFHAND) or NO_WEAPON_STRING
	ns.offhand.itemicon = GetInventoryItemTexture("player", INVSLOT_OFFHAND) or NO_ICON
	ns.offhand.poisonname = GetWeaponBuff(INVSLOT_OFFHAND) or NO_POISON_STRING
	ns.offhand.poisonicon = POISON_ICONS[ns.offhand.poisonname] or NO_ICON
	ns.offhand.text = GetTimerText("offhand")
	------
	if hasThrownEnchant then
		ns.thrown.timeLeft = thrownExpiration / 1000
	else
		ns.thrown.timeLeft = 0
	end
	print("thrown", (thrownExpiration or 0) / 1000, ns.thrown.timeLeft)
	ns.thrown.itemlink = GetInventoryItemLink("player", INVSLOT_RANGED) or NO_WEAPON_STRING
	ns.thrown.itemicon = GetInventoryItemTexture("player", INVSLOT_RANGED) or NO_ICON
	ns.thrown.poisonname = GetWeaponBuff(INVSLOT_RANGED) or NO_POISON_STRING
	ns.thrown.poisonicon = POISON_ICONS[ns.thrown.poisonname] or NO_ICON
	ns.thrown.text = GetTimerText("thrown")
end

local function SetDefaults()
	BPT_DB = BPT_DB or {
		version = BPT_VERSION,
		mainhand = {string = "M: %M:%S", showicon = false},
		offhand  = {string = "O: %M:%S", showicon = false},
		thrown   = {string = "T: %M:%S", showicon = false},
	}
	
	if not BPT_DB.version or BPT_DB.version < 1.2 then --Update the DB to the 1.2 format
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
	
	if BPT_DB.version < 1.3 then --Update the DB to the 1.3 format
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
end

function f:PLAYER_ENTERING_WORLD()
	SetDefaults()
	self:InitialiseBuffTooltip()
	UpdateWeapons()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")--We only care about this when logging in, so no need to watch it after the initial fire.
end
f:RegisterEvent("PLAYER_ENTERING_WORLD")

function f:UNIT_INVENTORY_CHANGED(UIC, unit)
	if unit ~= "player" then return end
	UpdateWeapons()
end
f:RegisterEvent("UNIT_INVENTORY_CHANGED")

------------
--Tooltips--
------------

-- Pass GameTooltip as tooltip.
-- Pass "mainhand", "offhand" or "thrown" as objectname
local function OnTooltipShow(tooltip, objectname)
	tooltip:AddDoubleLine("PoisonTimers", ns[objectname].slotname)
	tooltip:AddDoubleLine("|T".. ns[objectname].itemicon ..":25|t", ns[objectname].itemlink, 1,1,1, 1,1,1)
	tooltip:AddDoubleLine("|T".. ns[objectname].poisonicon ..":25|t", ns[objectname].poisonname, 1,1,1, 1,1,1)
end

local function OnEnter(self, objectname)
	UpdateWeapons()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	OnTooltipShow(GameTooltip, objectname)
	GameTooltip:Show()
end

function ns.mainhand:OnEnter()
	OnEnter(self, "mainhand")
end

function ns.mainhand:OnLeave()
	GameTooltip:Hide()
end

function ns.offhand:OnEnter()
	OnEnter(self, "offhand")
end

function ns.offhand:OnLeave()
	GameTooltip:Hide()
end

function ns.thrown:OnEnter()
	OnEnter(self, "thrown")
end

function ns.thrown:OnLeave()
	GameTooltip:Hide()
end

-----------------
--Slash Command--
-----------------
local function IsValidName(name)
	return name == "mainhand" or name == "offhand" or name == "thrown"
end

SLASH_BROKER_POISONTIMERS1, SLASH_BROKER_POISONTIMERS2, SLASH_BROKER_POISONTIMERS3 = "/brokerpoisontimers", "/poisontimers", "/bpt"

SlashCmdList.BROKER_POISONTIMERS = function(input)
	local cmd, objectname, setting = input:trim():match("^(%a+)%s+(%a+)%s+(.+)$")
-- 	print(input:trim())
	cmd, objectname = (cmd or ""):lower(), (objectname or ""):lower()
-- 	print(objectname)
-- 	print(setting)
	if cmd == "string" and IsValidName(objectname) then
		BPT_DB[objectname].string = setting
		f:Print(("Timer string for %s set to %q"):format(objectname, setting))
	elseif cmd == "showicon" and IsValidName(objectname) then
		BPT_DB[objectname].showicon = (setting == "enable")
		f:Print(("Poison icon for %s %s."):format(objectname, setting == "enable" and "$green$enabled" or "$red$disabled"))
	else
		f:Print("Slash Command Usage.")
		f:TPrint(1, ("$red$%s|r or $red$%s|r or $red$%s command mainhand||offhand||thrown setting|r"):format(SLASH_BROKER_POISONTIMERS1, SLASH_BROKER_POISONTIMERS2, SLASH_BROKER_POISONTIMERS3))
		f:TPrint(2, "$red$showicon mainhand||offhand||thrown enable||disable|r -- Enable/disable showing of the poison/imbue icon next to the timer.")
		f:TPrint(2, "$red$string mainhand||offhand||thrown setting|r -- Changes the time format of the specified timer to $red$setting|r. $red$setting|r can contain all characters (including spaces).")
		f:TPrint(3, "$red$%M|r and $red$%S|r will be replaced with the minutes and seconds remaining, respectively. To display a percent sign in the format, you must use $red$%%|r. The default time format is \"$red$X: %M:%S|r\" (where $red$X|r is $red$M|r, $red$O|r or $red$T|r).")
		f:TPrint(3, "Several other tokens can be used in the time format, but only the minutes/seconds have meaningful values. The other tokens can be found at the link to \"strftime\" at $green$http://www.wowpedia.org/API_date|r.")
		f:TPrint(3, "If you get a Lua error telling you that the \"format is too long\", it actually means the function used to display the timers doesn't support one of the tokens you used.")
	end
end