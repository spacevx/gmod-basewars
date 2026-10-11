MODULE.Name = "AFK"
MODULE.Author = "Q2F2 & Ghosty"

local tag = "BaseWars.AFK"
local PLAYER = debug.getregistry().Player

function MODULE:IsAFK(ply)
	return (CurTime() - ply:GetNW2Int(tag)) > BaseWars.Config.AFK.Time
end
PLAYER.IsAFK = Curry(MODULE.IsAFK)

function MODULE:AFKTime(ply)
	return CurTime() - ply:GetNW2Int(tag)
end
PLAYER.AFKTime = Curry(MODULE.AFKTime)
