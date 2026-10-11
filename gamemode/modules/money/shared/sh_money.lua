MODULE.Name 	= "Money"
MODULE.Author 	= "Q2F2, Ghosty and Tenrys"

local tag = "BaseWars.Money"
local PLAYER = debug.getregistry().Player

function MODULE:GetMoney(ply)
	return tonumber(ply:GetNWString(tag)) or 0
end
PLAYER.GetMoney = Curry(MODULE.GetMoney)
