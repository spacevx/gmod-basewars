MODULE.Name 	= "AntiRDM"
MODULE.Author 	= "Q2F2 & Ghosty"

local tag = "BaseWars.AntiRDM"
local PLAYER = debug.getregistry().Player


function MODULE:IsRDM(ply, ply2)
	if ply == ply2 then return false end
	if ply:InRaid() and ply2:InRaid() then return false end
	if ply.RecentlyHurtBy[ply2] and ply.RecentlyHurtBy[ply2] < CurTime() + BaseWars.Config.AntiRDM.HurtTime then return false end
	return true
end

function MODULE:CalculateSpawnTime(ply)
	local delay = 0
	delay = delay + (ply.RDMS * BaseWars.Config.AntiRDM.RDMSecondsAdd)
	local karma = ply:GetKarma()
	if karma < 0 then
		karma = math.abs(karma)
		delay = delay + (karma / BaseWars.Config.AntiRDM.KarmaSecondPer)
	end
	return CurTime() + delay
end
PLAYER.CalculateSpawnTime = Curry(MODULE.CalculateSpawnTime)

function MODULE:OnEntityTakeDamage(ply, dmginfo)
	local Attacker = dmginfo:GetAttacker()
	if not BaseWars.Ents:ValidPlayer(Attacker) then return end
	ply.RecentlyHurtBy = ply.RecentlyHurtBy or {}
	ply.RecentlyHurtBy[Attacker] = CurTime()
end
hook.Add("OnTakeDamage", tag .. ".TakeDamage", Curry(MODULE.OnEntityTakeDamage))

function MODULE:PlayerDeath(ply, inflictor, attacker)
	if not BaseWars.Ents:ValidPlayer(attacker) then return end
	if self:IsRDM(ply, attacker) then
		attacker.RDMS = (attacker.RDMS or 0) + 1
		attacker:AddKarma(BaseWars.Config.AntiRDM.KarmaLoss)
	end
	ply.RecentlyHurtBy = {}
	ply.NextSpawn = ply:CalculateSpawnTime()
	ply.RDMS = 0
end
hook.Add("PlayerDeath", tag .. ".PlayerDeath", Curry(MODULE.PlayerDeath))

function MODULE:PlayerDeathThink(ply)
	if not ply.NextSpawn or ply.NextSpawn == math.huge or ply.NextSpawn ~= ply.NextSpawn then
		ply.NextSpawn = CurTime()
	end
	if CurTime() >= ply.NextSpawn then
		ply:SetNWInt("RespawnTime", 0)
	return end
	local Time = ply.NextSpawn - CurTime()
	if Time > 300 then Time = 300 end
	ply:SetNWInt("RespawnTime", Time)
	return false
end

hook.Add("PlayerDeathThink", tag .. ".PlayerDeathThink", Curry(MODULE.PlayerDeathThink))

function MODULE:PlayerInitialSpawn(ply)
	ply.NextSpawn = math.huge
	ply.RecentlyHurtBy = {}
	ply.RDMS = 0
end

hook.Add("PlayerInitialSpawn", tag .. ".PlayerInitialSpawn", Curry(MODULE.PlayerInitialSpawn))
