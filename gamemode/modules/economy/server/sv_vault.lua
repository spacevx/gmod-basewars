g_VaultLookup = g_VaultLookup or {}

hook.Add("BaseWars_PlayerCanBuyEntity", "money_vault", function(ply, class)
	if class:match("bw_vault") and IsValid(g_VaultLookup[ply:SteamID64()]) then
		return false, "You already own a money vault."
	end
end)

hook.Add("BaseWars_PlayerBuyEntity", "money_vault", function(ply, ent)
	if ent:GetClass():match("bw_vault") then
		g_VaultLookup[ply:SteamID64()] = ent
	end
end)

