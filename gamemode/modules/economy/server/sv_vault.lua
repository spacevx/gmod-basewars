local Economy = MODULE.Class
local economy = MODULE
economy.VaultLookup = economy.VaultLookup or {}

function Economy:CanBuyVault(ply, class)
	if class:match("bw_vault") and IsValid(self.VaultLookup[ply:SteamID64()]) then
		return false, "You already own a money vault."
	end
end

function Economy:TrackVault(ply, ent)
	if ent:GetClass():match("bw_vault") then
		self.VaultLookup[ply:SteamID64()] = ent
	end
end

hook.Add("BaseWars_PlayerCanBuyEntity", "money_vault", function(ply, class)
	return economy:CanBuyVault(ply, class)
end)

hook.Add("BaseWars_PlayerBuyEntity", "money_vault", function(ply, ent)
	economy:TrackVault(ply, ent)
end)

