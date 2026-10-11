MODULE.Name 	= "PlayerLevel"
MODULE.Author 	= "Q2F2 and Trixter"

local tag = "BaseWars.PlayerLevel"
local PLAYER = debug.getregistry().Player

function MODULE:GetLevel(ply)
	return tonumber(ply:GetNWString(tag .. ".Level")) or 0
end
PLAYER.GetLevel = Curry(MODULE.GetLevel)

function MODULE:GetXP(ply)
	return tonumber(ply:GetNWString(tag .. ".XP")) or 0
end
PLAYER.GetXP = Curry(MODULE.GetXP)

function MODULE:GetXPNextLevel(ply)
	local n = ply:GetLevel()
	return (n + 1) * 250
end
PLAYER.GetXPNextLevel = Curry(MODULE.GetXPNextLevel)

function MODULE:HasLevel(ply, level)
	local plylevel = ply:GetLevel()
	return (plylevel >= level)
end
PLAYER.HasLevel = Curry(MODULE.HasLevel)
