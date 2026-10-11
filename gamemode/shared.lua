GM.Name 			= "BaseWars"
GM.Author 		= "Q2F2, Ghosty, Trixter, Liquid, Tenrys, User4992"
GM.Website 		= "http://hexahedron.pw/, http://hexahedronic.github.io/"
GM.Credits		= [[
Thanks to the following people:
	Q2F2/Orbitei	- Main backend dev.
	Ghosty			- Main frontend dev.
	Trixter			- Frontend + Several entities.
	Liquid/Ling		- Misc dev, good friend.
	Tenrys			- Misc dev, good friend also.
	Pyro-Fire		- Owner of LagNation, ideas ect.
	Devenger		- Twitch Weaponry 2
	User4992		- Fixes for random stuff.

This GM has been built from scratch with no traces of the original BaseWars existing.
]]
GM.Copyright = [[
Copyright (c) 2015-2017 Hexahedronic et al
]]
GM.Translators = [[
Thank you to the following translators:
	Tenrys			- French
	_Fami			- French
	!_oplexz		- Russian
	Trixter			- Russian
	Ghosty			- Spanish
	Liquid			- Dutch
	Dennis			- German
	Archerity		- Korean

See GAMEMODE.Credits for the original English ver creators.
]]

-- Shared colors, feel free to add any here
NiceGreen	= Color(100, 250, 125)
NiceBlue	= Color(100, 125, 250)
Grey		= Color(200, 200, 200)
White		= Color(255, 255, 255)
Pink		= Color(255, 105, 180)

-- Starting!
BaseWars = BaseWars or {}
BaseWars.SpawnList = BaseWars.SpawnList or {}

function BaseWars.NewCAT(name, icon)
	local cat = {}
		cat.__inf = {}
		cat.__inf.name = name
		cat.__inf.icon = icon
	return cat
end

-- Ignore this, Lua refresh compat
if BaseWars.Factions and table.Count(BaseWars.Factions.FactionTable) > 0 then
	__BASEWARS_FACTION_BACKUP = table.Copy(BaseWars.Factions.FactionTable)
end

if BaseWars.Bounty and table.Count(BaseWars.Bounty.BountyTable) > 0 then
	__BASEWARS_BOUNTY_BACKUP = table.Copy(BaseWars.Bounty.BountyTable)
end

-- Thanks to whoever posted this, can't remember source.
function ents.FindInCone(cone_origin, cone_direction, cone_radius, cone_angle)
	local entities = ents.FindInSphere(cone_origin, cone_radius)
	local result = {}
	cone_direction:Normalize()
	local cos = math.cos(cone_angle)
	for _, entity in ipairs(entities) do
		local pos = entity:GetPos()
		local dir = pos - cone_origin
		dir:Normalize()
		local dot = cone_direction:Dot(dir)
		if dot > cos then
			table.insert(result, entity)
		end
	end
	return result
end

function BaseWars.IsXmasTime(day)
	local Month = tonumber(os.date("%m"))
	local Day	= tonumber(os.date("%d"))
	return Month == 12 and (not day or (Day == 24 or Day == 25))
end

local DefaultData = {
	__index = {
		Model = "models/props_c17/FurnitureToilet001a.mdl",
		Price = 0,
		ClassName = "prop_physics",
		ShouldFreeze = true,
	}
}

function BaseWars.GSL(t)
	if t.Drug then
		t.Model = "models/props_junk/PopCan01a.mdl"
	end
	if not t.Limit then
		t.Limit = BaseWars.Config.DefaultLimit
	end
	if t.VehicleName then
		t.ShouldFreeze = false
	end
	return setmetatable(t, DefaultData)
end

BASEWARS_NOTIFICATION_ADMIN = color_white
BASEWARS_NOTIFICATION_ERROR = Color(255, 0, 0, 255)
BASEWARS_NOTIFICATION_MONEY = Color(0, 255, 0, 255)
BASEWARS_NOTIFICATION_RAID 	= Color(255, 255, 0, 255)
BASEWARS_NOTIFICATION_GENRL = Color(255, 0, 255, 255)
BASEWARS_NOTIFICATION_DRUG	= Color(0, 255, 255, 255)

function GM:PlayerIsRaidable(ply)
	if BaseWars.Config.Raid.NeededPrinters < 1 then return end
	local Raids = 0
	BaseWars.CPPI.ForEachOwned(ply, function(ent)
		if not ent.IsValidRaidable then return end
		Raids = Raids + 1
		if Raids >= BaseWars.Config.Raid.NeededPrinters then return false end
	end)
	if Raids >= BaseWars.Config.Raid.NeededPrinters then return true end
	return false, BaseWars.LANG.NoPrinters
end

function BaseWars.GetRaidables(ply)
	local list = {}
	if SERVER and BaseWars.CPPI.HasIndexedOwners() then
		local members = ply:InFaction() and ply:FactionMembers() or {ply}
		for _, member in pairs(members) do
			BaseWars.CPPI.ForEachOwned(member, function(ent, owner)
				if ent:GetClass():sub(1, 3) ~= "bw_" then return end
				list[#list + 1] = {e = ent, r = ent.IsValidRaidable or false, o = owner}
			end)
		end
		return list
	end
	for k, v in ipairs(ents.FindByClass"bw_*") do
		local own = BaseWars.CPPI.GetOwner(v)
		if BaseWars.Ents:ValidPlayer(own) and (own == ply or (own:InFaction(ply:GetFaction()) and ply:InFaction())) then
			list[#list+1] = {e = v, r = v.IsValidRaidable or false, o = own}
		end
	end
	return list
end

local tag = "BaseWars.UTIL"

BaseWars.UTIL = {}

local colorRed 		= Color(255, 0, 0)
local colorBlue 	= Color(0, 0, 255)
local colorWhite 	= Color(255, 255, 255)

function BaseWars.UTIL.Log(...)
	MsgC(SERVER and colorRed or colorBlue, "[BaseWars] ", colorWhite, ...)
	MsgN("")
end

function BaseWars.UTIL.TimerAdv(name, spacing, reps, tickf, endf)
	timer.Create(name, spacing * reps, 1, endf)
	timer.Create(name .. ".Tick", spacing, reps, tickf)
end

function BaseWars.UTIL.TimerAdvDestroy(name)
	timer.Destroy(name)
	timer.Destroy(name .. ".Tick")
end

function BaseWars.UTIL.TimeParse(len)
	local len = math.abs(math.floor(len))
	local h = math.floor(len / 60 / 60)
	local m = math.floor(len / 60 - h * 60)
	local s = math.floor(len - m * 60 - h * 60 * 60)
	return string.format("%.2d:%.2d:%.2d", h, m, s)
end

function BaseWars.UTIL.FreezeAll()
	for k, v in next, ents.GetAll() do
		if not BaseWars.Ents:Valid(v) then continue end
		local Phys = v:GetPhysicsObject()
		if not BaseWars.Ents:Valid(Phys) then continue end
		Phys:EnableMotion(false)
	end
end

function BaseWars.NumberFormat(num)
	local t = BaseWars.LANG.Numbers
	for i = 1, #t do
		local Div = t[i][1]
		local Str = t[i][2]
		if num >= Div or num <= -Div then
			return string.Comma(math.Round(num / Div, 1)) .. " " .. Str
		end
	end
	return string.Comma(math.Round(num, 1))
end

local PlayersCol = Color(125, 125, 125, 255)
team.SetUp(1, "No Faction", PlayersCol)

function GM:PlayerNoClip(ply)
	return ply:IsAdmin() and not ply:InRaid()
end

local function BlockInteraction(ply, ent, ret)
	if ent then
		if not BaseWars.Ents:Valid(ent) then return false end
		local Classes = BaseWars.Config.PhysgunBlockClasses
		local class = ent:GetClass()
		if class:find("_door") or class:find("func_") then return false end
		if Classes[class] then return false end
		local Owner = BaseWars.CPPI.GetOwner(ent)
		if BaseWars.Ents:ValidPlayer(ply) and ply:InRaid() then return false end
		if BaseWars.Ents:ValidPlayer(Owner) and Owner:InRaid() then return false end
	elseif ply:InRaid() then
		return false
	end
	return ret == nil or ret
end

local function IsAdmin(ply, ent, ret)
	if BlockInteraction(ply, ent, ret) == false then return false end
	return ply:IsAdmin()
end

function GM:PhysgunPickup(ply, ent)
	local Ret = self.BaseClass:PhysgunPickup(ply, ent)
	if ent:IsVehicle() then return IsAdmin(ply, ent, Ret) end
	ent.beingPhysgunned = ent.beingPhysgunned or {}
	local found = false
	for k, v in ipairs(ent.beingPhysgunned) do
		if v == ply then found = true break end
	end
	if not found then
		ent.beingPhysgunned[#ent.beingPhysgunned + 1] = ply
	end
	return BlockInteraction(ply, ent, Ret)
end

function GM:PhysgunDrop(ply, ent)
	if ent.beingPhysgunned then
		for k, v in ipairs(ent.beingPhysgunned) do
			if v == ply then table.remove(ent.beingPhysgunned, k) break end
		end
	end
	return self.BaseClass:PhysgunDrop(ply, ent)
end

function GM:CanPlayerUnfreeze(ply, ent, phys)
	local Ret = self.BaseClass:CanPlayerUnfreeze(ply, ent, phys)
	return BlockInteraction(ply, ent, Ret)
end

local stupidStuff = {
	["precision"] = true,
	["inflator"] = true,
	["paint"] = true,
	["color"] = true,
	["fading_door"] = true,
	["material"] = true,
}
function GM:CanTool(ply, tr, tool)
	local ent = tr.Entity
	if ent == game.GetWorld() then ent = nil end
	local Ret = self.BaseClass:CanTool(ply, tr, tool)
	if BaseWars.Config.BlockedTools[tool] then return IsAdmin(ply, ent, Ret) end
	if BaseWars.Ents:Valid(ent) and ent:GetClass():find("bw_") then return IsAdmin(ply, ent, Ret) end
	if SERVER and not stupidStuff[tool] then
		local Pos = tr.HitPos
		local HitString = math.floor(Pos.x) .. "," .. math.floor(Pos.y) .. "," .. math.floor(Pos.z)
		BaseWars.UTIL.Log("TOOL EVENT: ", ply, " -> ", tool, " on pos [", HitString, "]")
	end
	return BlockInteraction(ply, ent, Ret)
end

function GM:PlayerSpawnObject(ply, model, ...)
	local Ret = self.BaseClass:PlayerSpawnObject(ply, model, ...)
	return BlockInteraction(ply, nil, Ret)
end

function GM:CanDrive()
	-- I'm sick of this
	return false
end

function GM:OnPhysgunReload()
	-- Stop crashing our server
	return false
end

function GM:CanProperty(ply, prop, ent, ...)
	local Ret = self.BaseClass:CanProperty(ply, prop, ent, ...)
	if not IsValid(ent) then return Ret end
	local Class = ent:GetClass()
	if prop == "persist" 	then return false end
	if prop == "ignite" 	then return false end
	if prop == "extinguish" then return IsAdmin(ply, ent, Ret) end
	if prop == "remover" and Class:find("bw_") then return IsAdmin(ply, ent, Ret) end
	return BlockInteraction(ply, ent, Ret)
end

function GM:GravGunPunt(ply, ent)
	local Ret = self.BaseClass:GravGunPunt(ply, ent)
	if not IsValid(ent) then return Ret end
	local Class = ent:GetClass()
	if ent:IsVehicle() then return false end
	if Class == "prop_physics" then return BaseWars.Config.AllowPropPunt end
	return BlockInteraction(ply, ent, Ret)
end

local NoSounds = {
	"vo/engineer_no01.mp3",
	"vo/engineer_no02.mp3",
	"vo/engineer_no03.mp3",
}
function GM:PlayerSpawnProp(ply, model)
	local Ret = self.BaseClass:PlayerSpawnProp(ply, model)
	local EscapedModel = model:lower():gsub("\\","/"):gsub("//", "/"):Trim()
	if BaseWars.Config.ModelBlacklist[EscapedModel] then
		ply:EmitSound(NoSounds[math.random(1, #NoSounds)], 140)
	return end
	Ret = (Ret == nil or Ret)
	if Ret then
		BaseWars.UTIL.Log("PROP EVENT: ", ply, " -> ", EscapedModel)
	end
	return Ret == nil or Ret
end
