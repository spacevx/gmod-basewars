MODULE.Name = "Economy"
MODULE.Author = "Q2F2, Ghosty, Tenrys and Trixter"

local Economy = {}
Economy.__index = Economy

setmetatable(MODULE, Economy)
MODULE.Class = Economy

function Economy:__INIT()
	BaseWars.Money = self
	BaseWars.PlayerLevel = self
	BaseWars.PlayTime_Money = self
end
