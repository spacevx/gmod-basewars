local Economy = MODULE.Class
local economy = MODULE

function Economy:Pay(ply, amt, name, own)
	ply:Notify(string.format(own and BaseWars.LANG.PayOutOwner or BaseWars.LANG.PayOut, BaseWars.NumberFormat(amt), name), BASEWARS_NOTIFICATION_GENRL)
	ply:GiveMoney(amt)
end

function Economy:PayOut(ent, attacker, full, ret)
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
		self:Pay(Owner, Val, Name, true)
	return 0 end
	local Members = attacker:FactionMembers()
	local TeamAmt = table.Count(Members)
	local Involved = Owner and TeamAmt + 1 or TeamAmt
	local Fraction = math.floor(Val / Involved)
	if TeamAmt > 1 then
		for k, v in next, Members do
			self:Pay(v, Fraction, Name)
		end
	else
		self:Pay(attacker, Fraction, Name)
	end
	if Owner then
		self:Pay(Owner, Fraction, Name, true)
	end
	return Val
end

function Economy:RefundAll(ply, ret)
	if not ply and not ret then BaseWars.UTIL.Log("FULL SERVER REFUND IN PROGRESS!!!") end
	local RetTbl = {}
	if ret then
		for k, v in next, player.GetAll() do
			RetTbl[v:SteamID64()] = 0
		end
	end
	BaseWars.CPPI.ForEachOwned(ply, function(v, Owner)
		if not v.CurrentValue then return end
		if not ret then
			self:PayOut(v, Owner, true, ret)
			v:Remove()
		else
			RetTbl[Owner:SteamID64()] = RetTbl[Owner:SteamID64()] + self:PayOut(v, Owner, true, ret)
		end
	end)
	return RetTbl
end

function Economy:WriteCrashRollback()
	BaseWars.MySQL.SaveCrashRefunds(self:RefundAll(nil, true))
end

function Economy:RefundFromCrash(ply)
	BaseWars.MySQL.RefundFromCrash(ply)
end

function Economy:ClearRollbackFile(ply)
	BaseWars.MySQL.ClearCrashRefund(ply)
end

function Economy:SafeShutDown()
	self:RefundAll()
	BaseWars.MySQL.ClearAllCrashRefunds()
end

function BaseWars.UTIL.PayOut(ent, attacker, full, ret)
	return economy:PayOut(ent, attacker, full, ret)
end

function BaseWars.UTIL.RefundAll(ply, ret)
	return economy:RefundAll(ply, ret)
end

function BaseWars.UTIL.WriteCrashRollback()
	return economy:WriteCrashRollback()
end

function BaseWars.UTIL.RefundFromCrash(ply)
	return economy:RefundFromCrash(ply)
end

function BaseWars.UTIL.ClearRollbackFile(ply)
	return economy:ClearRollbackFile(ply)
end

function BaseWars.UTIL.SafeShutDown()
	return economy:SafeShutDown()
end
