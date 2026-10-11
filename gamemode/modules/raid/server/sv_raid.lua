local tag = "BaseWars.Raid"
local PLAYER = debug.getregistry().Player
local state = MODULE.State

util.AddNetworkString(tag)

function MODULE:HandleNetMessage(len, ply)
	local mode = net.ReadUInt(2)
	if mode == 0 then
		self:Start(ply, net.ReadEntity())
	elseif mode == 1 then
		self:ConceedRaid(ply)
	end
end
net.Receive(tag, Curry(MODULE.HandleNetMessage))

local checkParticipants = MODULE.CheckForNULL
function MODULE:CheckForNULL()
	if not checkParticipants(self) then return false end
	if state.IsFaction then
		return BaseWars.Factions:FactionExist(state.P1Faction)
			and BaseWars.Factions:FactionExist(state.P2Faction)
	end
	return true
end

function MODULE:CheckRaidable(ply, nocool, fac)
	local Table = BaseWars.Factions.FactionTable
	local Faction = Table[ply:GetFaction()]
	if not nocool then
		local Cool = CurTime() - (Faction and Faction.__RaidCoolDown or ply.__RaidCoolDown or 0)
		local Left = math.floor(BaseWars.Config.Raid.CoolDownTime - Cool)
		if Cool < BaseWars.Config.Raid.CoolDownTime then return false, BaseWars.LANG.OnCoolDown .. " (" .. string.NiceTime(Left) .. " " .. BaseWars.LANG.Remaining .. ")" end
	end
	local Call, Message = hook.Run("PlayerIsRaidable", ply)
	if Call == false and Faction then
		for k, v in next, Faction.members do
			Call, Message = hook.Run("PlayerIsRaidable", v)
			if Call == true then break end
		end
	end
	if Call == false then
		return false, Message
	end
	return true
end
PLAYER.Raidable = Curry(MODULE.CheckRaidable)

local timerTick = MODULE.TimerTick
function MODULE:TimerTick()
	if not self:CheckForNULL() then
		self:EndRaid()
		return
	end
	timerTick(self)
end
local tick = Curry(MODULE.TimerTick)
local fend = Curry(MODULE.TimerEnd)

function MODULE:Start(ply, target)
	if not target or not target:IsPlayer() then
		ErrorNoHalt("RaidStart, invalid target.")
		debug.Trace()
		return
	end
	if self:IsOnGoing() then
		ply:Notify(BaseWars.LANG.RaidOngoing, BASEWARS_NOTIFICATION_RAID)
		return
	end
	if ply == target then
		ply:Notify(BaseWars.LANG.CantRaidSelf, BASEWARS_NOTIFICATION_RAID)
		return
	end
	if ply:InFaction() and not target:InFaction() then
		ply:Notify(BaseWars.LANG.RaidTargNoFac, BASEWARS_NOTIFICATION_RAID)
		return
	end
	if target:InFaction() and not ply:InFaction() then
		ply:Notify(BaseWars.LANG.RaidSelfNoFac, BASEWARS_NOTIFICATION_RAID)
		return
	end
	state.IsFaction = ply:InFaction()
	local Ret, Msg
	Ret, Msg = self:CheckRaidable(ply, true, state.IsFaction)
	if not Ret then
		ply:Notify(string.format(BaseWars.LANG.RaidSelfUnraidable, Msg or "UNKNOWN!"), BASEWARS_NOTIFICATION_RAID)
		return
	end
	Ret, Msg = self:CheckRaidable(target, false, state.IsFaction)
	if not Ret then
		ply:Notify(string.format(BaseWars.LANG.RaidTargetUnraidable, Msg or "UNKNOWN!"), BASEWARS_NOTIFICATION_RAID)
		return
	end
	if state.IsFaction and target:InFaction(ply:GetFaction()) then
		ply:Notify(BaseWars.LANG.CantRaidSelf, BASEWARS_NOTIFICATION_RAID)
		return
	end
	state.Participant1 = ply
	state.Participant2 = target
	state.P1Faction = state.Participant1:GetFaction()
	state.P2Faction = state.Participant2:GetFaction()
	hook.Run("RaidStart", ply, target, state.IsFaction)
	local Table = BaseWars.Factions.FactionTable
	local Faction = Table[state.P1Faction]
	if Faction then Faction.__RaidCoolDown = 0 else ply.__RaidCoolDown = 0 end
	state.TimeRemaining = BaseWars.Config.Raid.Time
	local Faction2 = Table[state.P2Faction]
	if Faction2 then Faction2.__RaidCoolDown = CurTime() + state.TimeRemaining else target.__RaidCoolDown = CurTime() + state.TimeRemaining end
	net.Start(tag)
		net.WriteUInt(0, 2)
		net.WriteInt(state.TimeRemaining, 16)
		net.WriteEntity(ply)
		net.WriteEntity(target)
		net.WriteBool(state.IsFaction)
	net.Broadcast()
	for k,v in pairs(player.GetAll()) do if v:GetFaction() == state.P1Faction or v:GetFaction() == state.P2Faction then v:EmitSound("ambient/alarms/warningbell1.wav", 60) end end
	BaseWars.UTIL.TimerAdv(tag, 1, BaseWars.Config.Raid.Time, tick, fend)
	local name1, name2 = self:GetVersus()
	BaseWars.Util_Player:NotificationAll(string.format(BaseWars.LANG.RaidStart, name1, name2), BASEWARS_NOTIFICATION_RAID)
end
PLAYER.StartRaid = Curry(MODULE.Start)

function MODULE:ConceedRaid(ply)
	if not ply:InRaid() then return end
	if state.IsFaction and not ply:InFaction(state.P1Faction, true) then return end
	if not state.IsFaction and ply ~= state.Participant1 then return end
	self:EndRaid()
end
PLAYER.ConceedRaid = Curry(MODULE.ConceedRaid)

local endRaid = MODULE.EndRaid
function MODULE:EndRaid()
	if not self:IsOnGoing() then return end
	net.Start(tag)
		net.WriteUInt(1, 2)
	net.Broadcast()
	local name1, name2 = self:GetVersus()
	BaseWars.Util_Player:NotificationAll(string.format(BaseWars.LANG.RaidOver, name1, name2), BASEWARS_NOTIFICATION_RAID)
	endRaid(self)
end

local function FalseInRaid(ply)
	if ply:InRaid() then return false, BaseWars.LANG.RaidNoFaction end
end
hook.Add("CanCreateFaction", tag, FalseInRaid)
hook.Add("CanLeaveFaction", tag, FalseInRaid)
hook.Add("CanJoinFaction", tag, FalseInRaid)
