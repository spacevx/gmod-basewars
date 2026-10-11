local Economy = MODULE.Class
local economy = MODULE
local PLAYER = debug.getregistry().Player

function Economy:GetMoney(ply)
	return ply.BaseWarsMoney or 0
end

function PLAYER:GetMoney()
	return economy:GetMoney(self)
end
