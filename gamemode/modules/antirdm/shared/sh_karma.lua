local tag = "BaseWars.Karma"
local PLAYER = debug.getregistry().Player

function MODULE:Get(ply)
	return tonumber(ply:GetNWString(tag)) or 0
end
PLAYER.GetKarma = Curry(MODULE.Get)
