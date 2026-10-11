hook.Add("EntityTakeDamage", "fuck_grenades", function(t, d)
	local inf = d:GetInflictor()
	if IsValid(inf) and inf:GetClass() == "cw_grenade_thrown" and IsValid(t) and not t:IsPlayer() then
		d:ScaleDamage(0.025)
	end
end)
