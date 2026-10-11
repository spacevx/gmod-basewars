MODULE.Name = "Raid"
MODULE.Author = "Q2F2 & Ghosty"

local tag = "BaseWars.Raid"
local PLAYER = debug.getregistry().Player

MODULE.State = {
	TimeRemaining = 0,
	IsFaction = false,
	Participant1 = nil,
	Participant2 = nil,
	P1Faction = nil,
	P2Faction = nil
}
local state = MODULE.State

function MODULE:GetP1()
	return state.Participant1
end

function MODULE:GetP2()
	return state.Participant2
end

function MODULE:IsFaction()
	return state.IsFaction
end

function MODULE:CheckForNULL()
	if not BaseWars.Ents:ValidPlayer(state.Participant1) or not BaseWars.Ents:ValidPlayer(state.Participant2) then
		return false
	end
	return true
end

function MODULE:IsOnGoing()
	return state.TimeRemaining > 0 and state.TimeRemaining
end

function MODULE:PlayerInvolved(ply)
	if not self:IsOnGoing() then
		return false
	end
	if state.Participant1 == ply or state.Participant2 == ply then
		return true
	end
	if state.IsFaction and (ply:InFaction(state.P1Faction) or ply:InFaction(state.P2Faction)) then
		return true
	end
	return false
end
PLAYER.InRaid = Curry(MODULE.PlayerInvolved)

function MODULE:TimerTick()
	if state.TimeRemaining > 0 then
		state.TimeRemaining = state.TimeRemaining - 1
	end
end

function MODULE:TimerEnd()
	self:EndRaid()
end

function MODULE:GetVersus()
	if not self:CheckForNULL() then
		ErrorNoHalt("NULL CHECK FAILED FOR RAID!\n")
		return BaseWars.LANG.NoFaction, BaseWars.LANG.NoFaction
	end
	local TrimTo = 21
	local name1, name2
	if state.IsFaction then
		name1 = state.Participant1:GetFaction():Trim()
		name2 = state.Participant2:GetFaction():Trim()
	else
		name1 = state.Participant1:Nick():Trim()
		name2 = state.Participant2:Nick():Trim()
	end
	if utf8.sub then
		name1 = utf8.sub(name1, 1, TrimTo):Trim() .. (utf8.len(name1) > TrimTo and "..." or "")
		name2 = utf8.sub(name2, 1, TrimTo):Trim() .. (utf8.len(name2) > TrimTo and "..." or "")
	else
		name1 = name1:sub(1, TrimTo):Trim() .. (string.len(name1) > TrimTo and "..." or "")
		name2 = name2:sub(1, TrimTo):Trim() .. (string.len(name2) > TrimTo and "..." or "")
	end
	return name1, name2
end

function MODULE:EndRaid()
	if not self:IsOnGoing() then return end
	hook.Run("RaidEnded")
	state.TimeRemaining = 0
	state.IsFaction = false
	state.Participant1 = nil
	state.Participant2 = nil
	state.P1Faction = nil
	state.P2Faction = nil
	BaseWars.UTIL.TimerAdvDestroy(tag)
end
