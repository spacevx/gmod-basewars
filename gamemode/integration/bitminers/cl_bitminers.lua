if not file.Exists("bitminers2_config.lua", "LUA")
	or not file.Exists("bitminers2_extra_config.lua", "LUA") then return end

DarkRP = DarkRP or {}
DarkRP.formatMoney = DarkRP.formatMoney or function(amount)
	return BaseWars.NumberFormat(tonumber(amount) or 0)
end
