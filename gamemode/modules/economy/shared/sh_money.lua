local PLAYER = debug.getregistry().Player

function MODULE:GetMoney(ply)
	return ply.BaseWarsMoney or 0
end
PLAYER.GetMoney = Curry(MODULE.GetMoney)
