local function Pay(ply, amt, name, own)
	ply:Notify(string.format(own and BaseWars.LANG.PayOutOwner or BaseWars.LANG.PayOut, BaseWars.NumberFormat(amt), name), BASEWARS_NOTIFICATION_GENRL)
	ply:GiveMoney(amt)
end

function BaseWars.UTIL.PayOut(ent, attacker, full, ret)
	if not BaseWars.Ents:Valid(ent) or not BaseWars.Ents:ValidPlayer(attacker) then return 0 end
	if not ent.CurrentValue then ErrorNoHalt("ERROR! NO CURRENT VALUE! CANNOT PAY OUT!\n") return 0 end
	local Owner = BaseWars.Ents:ValidOwner(ent)
	local Val = ent.CurrentValue * (not full and not ret and BaseWars.Config.DestroyReturn or 1)
	if Val ~= Val or Val == math.huge then
		ErrorNoHalt("NAN OR INF RETURN DETECTED! HALTING!\n")
		ErrorNoHalt("...INFINITE MONEY GLITCH PREVENTED!!!\n")
	return 0 end
	if ret then return Val end
	local Name = ent.PrintName or ent:GetClass()
	if ent.IsPrinter then Name = BaseWars.LANG.Level .. " " .. ent:GetLevel() .. " " .. Name end
	if attacker == Owner then
		Pay(Owner, Val, Name, true)
	return 0 end
	local Members = attacker:FactionMembers()
	local TeamAmt = table.Count(Members)
	local Involved = Owner and TeamAmt + 1 or TeamAmt
	local Fraction = math.floor(Val / Involved)
	if TeamAmt > 1 then
		for k, v in next, Members do
			Pay(v, Fraction, Name)
		end
	else
		Pay(attacker, Fraction, Name)
	end
	if Owner then
		Pay(Owner, Fraction, Name, true)
	end
	return Val
end

function BaseWars.UTIL.RefundAll(ply, ret)
	if not ply and not ret then BaseWars.UTIL.Log("FULL SERVER REFUND IN PROGRESS!!!") end
	local RetTbl = {}
	if ret then
		for k, v in next, player.GetAll() do
			RetTbl[v:SteamID64()] = 0
		end
	end
	for k, v in next, ents.GetAll() do
		if not BaseWars.Ents:Valid(v) then continue end
		local Owner = BaseWars.Ents:ValidOwner(v)
		if not Owner or (ply and ply ~= Owner) then continue end
		if not v.CurrentValue then continue end
		if not ret then
			BaseWars.UTIL.PayOut(v, Owner, true, ret)
			v:Remove()
		else
			RetTbl[Owner:SteamID64()] = RetTbl[Owner:SteamID64()] + BaseWars.UTIL.PayOut(v, Owner, true, ret)
		end
	end
	return RetTbl
end

function BaseWars.UTIL.WriteCrashRollback()
	BaseWars.MySQL.SaveCrashRefunds(BaseWars.UTIL.RefundAll(nil, true))
end

function BaseWars.UTIL.RefundFromCrash(ply)
	BaseWars.MySQL.RefundFromCrash(ply)
end

function BaseWars.UTIL.ClearRollbackFile(ply)
	BaseWars.MySQL.ClearCrashRefund(ply)
end

function BaseWars.UTIL.SafeShutDown()
	BaseWars.UTIL.RefundAll()
	BaseWars.MySQL.ClearAllCrashRefunds()
end
