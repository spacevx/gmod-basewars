local tag = "BaseWars.AFK"
local PLAYER = debug.getregistry().Player
local SWEEP_INTERVAL = 1
local ANGLE_CHECK_INTERVAL = 3

util.AddNetworkString(tag)

function MODULE:SendState(ply)
	if not ply.afkClientReady then return end
	local afk = ply.afk == true
	net.Start(tag)
		net.WriteBool(afk)
		if afk then net.WriteFloat(ply.afkSince) end
	net.Send(ply)
end

function MODULE:MarkActive(ply, now)
	ply.afkSince = now
	if not ply.afk then return end
	ply.afk = false
	self:SendState(ply)
end

function MODULE:ResetPlayer(ply)
	ply.afkAngles = nil
	ply.afkNextAngleCheck = nil
	self:MarkActive(ply, CurTime())
end

function MODULE:SweepPlayer(ply, now, limit)
	local since = ply.afkSince
	if not since then
		ply.afkSince = now
		return
	end
	if now >= (ply.afkNextAngleCheck or 0) or (not ply.afk and now - since > limit) then
		local angles = ply:EyeAngles()
		local lastAngles = ply.afkAngles
		ply.afkAngles = angles
		ply.afkNextAngleCheck = now + ANGLE_CHECK_INTERVAL
		if lastAngles and lastAngles ~= angles then
			self:MarkActive(ply, now)
			return
		end
	end
	if ply.afk then return end
	if now - since <= limit then return end
	ply.afk = true
	self:SendState(ply)
end

function MODULE:Sweep()
	local now = CurTime()
	local limit = BaseWars.Config.AFK.Time
	for _, ply in player.Iterator() do
		self:SweepPlayer(ply, now, limit)
	end
end

function MODULE:ClearAFK(ply)
	self:MarkActive(ply, CurTime())
end
PLAYER.ClearAFK = Curry(MODULE.ClearAFK)

function MODULE:OnActivity(ply)
	self:MarkActive(ply, CurTime())
end

function MODULE:IsAFK(ply)
	local since = ply.afkSince
	return since ~= nil and CurTime() - since > BaseWars.Config.AFK.Time
end
PLAYER.IsAFK = Curry(MODULE.IsAFK)

function MODULE:AFKTime(ply)
	local since = ply.afkSince
	if not since then return 0 end
	return CurTime() - since
end
PLAYER.AFKTime = Curry(MODULE.AFKTime)

function MODULE:Receive(_, ply)
	local clear = net.ReadBool()
	local now = CurTime()
	if not clear then
		if (ply.afkNextSync or 0) > now then return end
		ply.afkNextSync = now + self.CLEAR_COOLDOWN
		ply.afkClientReady = true
		self:SendState(ply)
		return
	end
	if not ply.afk or (ply.afkNextClear or 0) > now then return end
	ply.afkNextClear = now + self.CLEAR_COOLDOWN
	self:MarkActive(ply, now)
end
net.Receive(tag, Curry(MODULE.Receive))

for _, ply in player.Iterator() do
	if not ply.afkSince then ply.afkSince = CurTime() end
end

timer.Create(tag .. ".Sweep", SWEEP_INTERVAL, 0, Curry(MODULE.Sweep))
hook.Add("PlayerInitialSpawn", tag .. ".Spawn", Curry(MODULE.ResetPlayer))
hook.Add("KeyPress", tag .. ".KeyPress", Curry(MODULE.OnActivity))
hook.Add("PlayerSay", tag .. ".PlayerSay", Curry(MODULE.OnActivity))
