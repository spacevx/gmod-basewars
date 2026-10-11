MODULE.Name 	= "Factions"
MODULE.Author 	= "Q2F2 & Ghosty"
MODULE.FactionTable = {}

local tag = "BaseWars.Factions"
local PLAYER = debug.getregistry().Player

function MODULE:Get(ply)
	return ply:GetNW2String(tag, "")
end

PLAYER.GetFaction = Curry(MODULE.Get)

function MODULE:InFaction(ply, name, leader)
	local Fac = ply:GetFaction()
	local Leader = not leader or ply:GetNW2Bool(tag .. ".Leader")
	if not name then
		return Fac ~= "" and Leader
	end
	return Fac == name and Leader
end
PLAYER.InFaction = Curry(MODULE.InFaction)

function MODULE:IsEnemy(ply, ply2)
	if ply == ply2 then return false end
	if ply:InFaction() and ply2:InFaction(ply:GetFaction()) then return false end
	if ply:GetNWBool("Unrestricted") or ply2:GetNWBool("Unrestricted") then return false end
	return true
end
PLAYER.IsEnemy = Curry(MODULE.IsEnemy)
