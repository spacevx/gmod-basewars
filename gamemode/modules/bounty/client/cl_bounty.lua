local tag = "BaseWars.Bounty"
local PLAYER = debug.getregistry().Player

function MODULE:GetBounty(ply)
	return ply:GetNW2Int(tag, 0)
end
PLAYER.GetBounty = Curry(MODULE.GetBounty)
