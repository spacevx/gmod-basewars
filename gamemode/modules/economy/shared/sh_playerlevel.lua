local tag = "BaseWars.PlayerLevel"
local Economy = MODULE.Class
local economy = MODULE
local PLAYER = debug.getregistry().Player

function Economy:GetLevel(ply)
	return tonumber(ply:GetNWString(tag .. ".Level")) or 0
end
function PLAYER:GetLevel()
	return economy:GetLevel(self)
end

function Economy:GetXP(ply)
	return tonumber(ply:GetNWString(tag .. ".XP")) or 0
end
function PLAYER:GetXP()
	return economy:GetXP(self)
end

function Economy:GetXPNextLevel(ply)
	local n = ply:GetLevel()
	return (n + 1) * 250
end
function PLAYER:GetXPNextLevel()
	return economy:GetXPNextLevel(self)
end

function Economy:HasLevel(ply, level)
	local plylevel = ply:GetLevel()
	return (plylevel >= level)
end
function PLAYER:HasLevel(level)
	return economy:HasLevel(self, level)
end
