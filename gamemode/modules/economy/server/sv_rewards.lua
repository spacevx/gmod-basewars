hook.Add("BaseWars_PlayerBuyEntity", "XPRewards", function(ply, ent)
	if ply:GetLevel() > 20 then return end
	ent = BaseWars.Ents:Valid(ent)
	if not ent then return end
	local mult = BaseWars.Config.XPMultiplier
	local class = ent:GetClass()
	if class:match("bw_printer_") or class == "bw_base_moneyprinter" then
		local level = (ent.CurrentValue or 1000) / 1000
		ply:AddXP(55 * level * mult)
	elseif class:match("bw_gen_") then
		ply:AddXP(125 * mult)
	elseif class == "bw_printerpaper" then
		ply:AddXP(25 * mult)
	end
end)

hook.Add("BaseWars_PlayerEmptyPrinter", "XPRewards", function(ply, ent, money)
	local mult = BaseWars.Config.XPMultiplier
	ply:AddXP(math.max(0, (money / 500) * mult))
end)
