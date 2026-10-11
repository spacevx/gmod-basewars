local provider = {}

function provider:IsInstalled()
	return gProtect or file.Exists("g_protect/sh_cppi.lua", "LUA")
end

function provider:IsAvailable()
	return gProtect and isfunction(gProtect.SetOwner) and isfunction(gProtect.GetOwnedEnts) and istable(gProtect.ownershipCache)
end

function provider:Sync(assigned)
	if self.SyncedCache == gProtect.ownershipCache then return end
	self.SyncedCache = gProtect.ownershipCache
	for ent, ply in pairs(assigned) do
		if IsValid(ent) and IsValid(ply) and ply:IsPlayer() and not IsValid(gProtect.ownershipCache[ent]) then
			local current = ent.CPPIGetOwner and ent:CPPIGetOwner()
			gProtect.SetOwner(IsValid(current) and current:IsPlayer() and current or ply, ent)
		end
	end
end

function provider:SetOwner(ent, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if ent.CPPISetOwner then ent:CPPISetOwner(ply) end
	if gProtect.ownershipCache[ent] ~= ply then gProtect.SetOwner(ply, ent) end
end

function provider:GetOwner(ent)
	local owner = gProtect.ownershipCache[ent]
	if IsValid(owner) then return owner end
end

function provider:ForEachOwned(ply, callback)
	local players = ply and {ply} or player.GetAll()
	for _, owner in ipairs(players) do
		if IsValid(owner) then
			for ent in pairs(gProtect.GetOwnedEnts(owner)) do
				if IsValid(ent) and self:GetOwner(ent) == owner and callback(ent, owner) == false then return end
			end
		end
	end
end

BaseWars.CPPI.RegisterProvider("gProtect", provider)
