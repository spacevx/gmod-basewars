MODULE.Name 	= "Util_Player"
MODULE.Author 	= "Q2F2 & Ghosty"

local PLAYER = debug.getregistry().Player

function MODULE:NotificationAll(text, col)
	self:Notification(nil, text, col)
end
NotifyAll = Curry(MODULE.NotificationAll)

function MODULE:Stuck(ply, pos)
	local t = {}
	t.start 	= pos or ply:GetPos()
	t.endpos 	= t.start
	t.filter 	= ply
	t.mask 		= MASK_PLAYERSOLID
	t.mins 		= ply:OBBMins()
	t.maxs 		= ply:OBBMaxs()
	t = util.TraceHull(t)
	local ent = t.Entity
	return t.StartSolid or (ent and (ent:IsWorld() or IsValid(ent)))
end
PLAYER.Stuck = Curry(MODULE.Stuck)
