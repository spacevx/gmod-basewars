local tag = "BaseWars.Raid"
local PLAYER = debug.getregistry().Player
local state = MODULE.State

surface.CreateFont(tag, {
	font = "Roboto",
	size = 30,
	weight = 800,
	antialias = true
})

function MODULE:HandleNetMessage()
	local mode = net.ReadUInt(2)
	if mode == 0 then
		self:CLIENT_SetupRaid(net.ReadInt(16), net.ReadEntity(), net.ReadEntity(), net.ReadBool())
	elseif mode == 1 then
		self:EndRaid()
	end
end
net.Receive(tag, Curry(MODULE.HandleNetMessage))

function MODULE:Start(ply, target)
	if not target or not target:IsPlayer() then
		ErrorNoHalt("RaidStart, invalid target.")
		debug.Trace()
		return
	end
	net.Start(tag)
		net.WriteUInt(0, 2)
		net.WriteEntity(target)
	net.SendToServer()
end
PLAYER.StartRaid = Curry(MODULE.Start)

function MODULE:ConceedRaid(ply)
	if not ply:InRaid() then return end
	if state.IsFaction and not ply:InFaction(state.P1Faction, true) then return end
	if not state.IsFaction and ply ~= state.Participant1 then return end
	net.Start(tag)
		net.WriteUInt(1, 2)
	net.SendToServer()
end
PLAYER.ConceedRaid = Curry(MODULE.ConceedRaid)

local tick = Curry(MODULE.TimerTick)

local PaintVS = ""

function MODULE:CLIENT_SetupRaid(t, versus, versus2, faction)
	state.TimeRemaining 	= t
	state.IsFaction		= faction
	state.Participant1	= versus
	state.Participant2	= versus2
	local name1, name2 = self:GetVersus()
	state.P1Faction = state.Participant1:GetFaction()
	state.P2Faction = state.Participant2:GetFaction()
	PaintVS = name1 .. BaseWars.LANG.VS .. name2
	hook.Run("RaidStart", versus, versus2, faction)
	BaseWars.UTIL.TimerAdv(tag, 1, BaseWars.Config.Raid.Time, tick, function() end)
end

function MODULE:Paint()
	if not self:IsOnGoing() then return end
	if state.TimeRemaining >= BaseWars.Config.Raid.Time - 5 then
		local sine = math.tan(RealTime() * 3) * 255
		surface.SetTextColor(255, sine, sine)
	else
		surface.SetTextColor(color_white)
	end
	surface.SetFont(tag)
	local w, h = surface.GetTextSize(PaintVS)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() - h - 1)
	surface.DrawText(PaintVS)
	local text = tostring(state.TimeRemaining) .. BaseWars.LANG.SecondsShort .. " " .. BaseWars.LANG.Remaining
	local w2, h2 = surface.GetTextSize(text)
	surface.SetTextPos(ScrW() / 2 - w2 / 2, ScrH() - h - h2 - 2)
	surface.DrawText(text)
end
hook.Add("HUDPaint", tag .. ".Paint", Curry(MODULE.Paint))
