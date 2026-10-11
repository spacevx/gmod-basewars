MODULE.Name 	= "Drugs"
MODULE.Author 	= "Q2F2 & Ghosty"

local tag = "BaseWars.Drugs"
local PLAYER = debug.getregistry().Player

function MODULE:HasDrug(ply, effect)
	return ply:GetNWBool(tag .. "." .. effect)
end
PLAYER.HasDrug = Curry(MODULE.HasDrug)
