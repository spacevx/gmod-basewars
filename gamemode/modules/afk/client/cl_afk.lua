local tag = "BaseWars.AFK"
local PLAYER = debug.getregistry().Player
local ACTIVITY_CHECK_INTERVAL = 1
local TEXT_COLOR = Color(255, 255, 255, 150)
local SHADOW_COLOR = Color(0, 0, 0, 140)
local SHADOW_OFFSET = 2

surface.CreateFont(tag, {
	font = "Roboto Condensed",
	size = 46,
	weight = 800,
})

function MODULE:RequestState()
	if not IsValid(LocalPlayer()) then return end
	net.Start(tag)
		net.WriteBool(false)
	net.SendToServer()
end

function MODULE:RequestClear()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply.afk then return end
	local now = RealTime()
	if (ply.afkNextClear or 0) > now then return end
	ply.afkNextClear = now + self.CLEAR_COOLDOWN
	net.Start(tag)
		net.WriteBool(true)
	net.SendToServer()
end

function MODULE:ClearAFK(ply)
	if ply ~= LocalPlayer() then return end
	self:RequestClear()
end
PLAYER.ClearAFK = Curry(MODULE.ClearAFK)

function MODULE:IsAFK(ply)
	return ply.afk == true
end
PLAYER.IsAFK = Curry(MODULE.IsAFK)

function MODULE:AFKTime(ply)
	local since = ply.afkSince
	if not since then return 0 end
	return CurTime() - since
end
PLAYER.AFKTime = Curry(MODULE.AFKTime)

function MODULE:Receive()
	local afk = net.ReadBool()
	local since = afk and net.ReadFloat() or nil
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	ply.afk = afk
	ply.afkSince = since
	ply.afkNextClear = nil
	self.LastViewAngles = nil
	self.LastCursorX = nil
	self.LastCursorY = nil
end
net.Receive(tag, Curry(MODULE.Receive))

function MODULE:CheckActivity()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply.afk then
		self.LastViewAngles = nil
		self.LastCursorX = nil
		self.LastCursorY = nil
		return
	end
	local angles = ply:EyeAngles()
	local movedView = self.LastViewAngles ~= nil and self.LastViewAngles ~= angles
	self.LastViewAngles = angles
	if movedView then self:RequestClear() end
	if not vgui.CursorVisible() then
		self.LastCursorX = nil
		self.LastCursorY = nil
		return
	end
	local x, y = input.GetCursorPos()
	local moved = self.LastCursorX ~= nil and (x ~= self.LastCursorX or y ~= self.LastCursorY)
	self.LastCursorX, self.LastCursorY = x, y
	if moved then self:RequestClear() end
end

function MODULE:GetTimeText(ply)
	local seconds = math.floor(ply:AFKTime())
	if seconds ~= self.CachedSeconds then
		self.CachedSeconds = seconds
		self.CachedText = BaseWars.UTIL.TimeParse(seconds)
	end
	return self.CachedText
end

function MODULE:DrawShadowedText(text, x, y)
	surface.SetTextColor(SHADOW_COLOR)
	surface.SetTextPos(x + SHADOW_OFFSET, y + SHADOW_OFFSET)
	surface.DrawText(text)
	surface.SetTextColor(TEXT_COLOR)
	surface.SetTextPos(x, y)
	surface.DrawText(text)
end

function MODULE:Paint()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply.afk then return end
	local text = self:GetTimeText(ply)
	surface.SetFont(tag)
	local centerX = ScrW() / 2
	local y = ScrH() / 3
	local timeW = surface.GetTextSize(text)
	self:DrawShadowedText(text, centerX - timeW / 2, y)
	local title = BaseWars.LANG.AFKFor
	local titleW, titleH = surface.GetTextSize(title)
	self:DrawShadowedText(title, centerX - titleW / 2, y - titleH - SHADOW_OFFSET)
end

timer.Create(tag .. ".Activity", ACTIVITY_CHECK_INTERVAL, 0, Curry(MODULE.CheckActivity))
hook.Add("InitPostEntity", tag .. ".Ready", Curry(MODULE.RequestState))
hook.Add("PlayerBindPress", tag, Curry(MODULE.RequestClear))
hook.Add("StartChat", tag, Curry(MODULE.RequestClear))
hook.Add("HUDPaint", tag .. ".Paint", Curry(MODULE.Paint))

if IsValid(LocalPlayer()) then timer.Simple(0, Curry(MODULE.RequestState)) end
