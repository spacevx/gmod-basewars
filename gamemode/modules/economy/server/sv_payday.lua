local tag = "BaseWars.Events"
local Economy = MODULE.Class
local economy = MODULE
local PLAYER = debug.getregistry().Player

function Economy:PayDay(ply)
	if not ply then
		for _, member in player.Iterator() do
			member:PayDay()
		end
		return
	end
	local money = ply:GetMoney()
	local baseRate = BaseWars.Config.PayDayBase
	local thousands = math.floor(money / BaseWars.Config.PayDayDivisor)
	local final = math.max(BaseWars.Config.PayDayMin, baseRate - thousands + math.random(-BaseWars.Config.PayDayRandom, BaseWars.Config.PayDayRandom))
	local donator = BaseWars.Config.ScaleVIPPayDay and BaseWars.Config.VIPRanks[ply:GetUserGroup()]
	if donator then final = math.max(math.floor(money * 0.002), final) end
	final = hook.Run("BW_PayDay", ply, final) or final
	if ply.AFKTime and ply:AFKTime() > 60 * 15 then
		local count = player.GetCount()
		if count >= math.min(game.MaxPlayers() / 5, 10) then
			ply:Notify("You just missed out on £" .. BaseWars.NumberFormat(final) .. " because you were AFK.", BASEWARS_NOTIFICATION_ERROR)
		else
			final = math.floor(final / 2)
			ply:Notify("You received a reduced PayDay of £" .. BaseWars.NumberFormat(final) .. " for seeding the server.", BASEWARS_NOTIFICATION_GENRL)
			ply:GiveMoney(final)
		end
	else
		ply:Notify(string.format(BaseWars.LANG.PayDay, BaseWars.NumberFormat(final)), BASEWARS_NOTIFICATION_MONEY)
		ply:GiveMoney(final)
	end
end
function PLAYER:PayDay()
	economy:PayDay(self)
end

timer.Create(tag .. ".PayDay", BaseWars.Config.PayDayRate, 0, function()
	economy:PayDay()
end)
