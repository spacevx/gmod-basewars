local tag = "BaseWars.AFK"
local PLAYER = debug.getregistry().Player

surface.CreateFont(tag, {
	font = "Roboto Condensed",
	size = 46,
	weight = 800,
})

function MODULE:ClearAFK(ply)
	if ply and ply ~= LocalPlayer() then return end
	net.Start(tag)
		net.WriteUInt(0, 2)
	net.SendToServer()
end
PLAYER.ClearAFK = Curry(MODULE.ClearAFK)

local trans = Color(255, 255, 255, 150)
local shade = Color(0, 0, 0, 140)

function MODULE:Paint()
	local ply = LocalPlayer()
	if not ply:IsAFK() then return end
	local len = ply:AFKTime()
	local AFKTime = BaseWars.UTIL.TimeParse(len)
	surface.SetFont(tag)
	local w, h = surface.GetTextSize(AFKTime)
	surface.SetTextColor(shade)
	surface.SetTextPos(ScrW() / 2 - w / 2 + 2, ScrH() / 3 + 2)
	surface.DrawText(AFKTime)
	surface.SetTextColor(trans)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 3)
	surface.DrawText(AFKTime)
	local Txt = BaseWars.LANG.AFKFor
	local w2, h2 = surface.GetTextSize(Txt)
	surface.SetTextColor(shade)
	surface.SetTextPos(ScrW() / 2 - w2 / 2 + 2, ScrH() / 3 - h2)
	surface.DrawText(Txt)
	surface.SetTextColor(trans)
	surface.SetTextPos(ScrW() / 2 - w2 / 2, ScrH() / 3 - h2 - 2)
	surface.DrawText(Txt)
end
hook.Add("HUDPaint", tag .. ".Paint", Curry(MODULE.Paint))

local clear = Curry(MODULE.ClearAFK)
local ox, oy, oa

local function cmdclear(cmd)
	local ply = LocalPlayer()
	if ply:IsAFK() and cmd:GetMouseX() ~= ox or cmd:GetMouseY() ~= oy then
		clear()
		ox, oy = cmd:GetMouseX(), cmd:GetMouseY()
	end
end

local function tickclear()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply.IsAFK and ply:IsAFK() and ply:GetAngles() ~= oa then
		clear()
	end
	oa = ply:GetAngles()
end

hook.Add("PlayerBindPress", tag, clear)
hook.Add("CreateMove", tag, cmdclear)
hook.Add("Tick", tag, tickclear)
hook.Add("StartChat", tag, clear)
