MODULE.Name 	= "AntiRDM"
MODULE.Author 	= "Q2F2 & Ghosty"

local tag = "BaseWars.AntiRDM"
local PLAYER = debug.getregistry().Player


surface.CreateFont(tag, {
	font = "Roboto Condensed",
	size = 46,
	weight = 800,
})

function MODULE:GetRespawnTime(ply)
	return ply:GetNWInt("RespawnTime", 0)
end

PLAYER.GetRespawnTime = Curry(MODULE.GetRespawnTime)

function MODULE:Paint()
	local ply = LocalPlayer()
	if (ply.IsAFK and ply:IsAFK()) or not ply:GetRespawnTime() or ply:Alive() then return end
	local len = ply:GetRespawnTime()
	if len < 1 then return end
	local m = math.floor(len / 60) % 60
	local s = math.floor(len) % 60
	local RespawnTime = string.format("%.2d:%.2d", m, s)
	surface.SetFont(tag)
	local w, h = surface.GetTextSize(RespawnTime)
	surface.SetTextColor(color_black)
	surface.SetTextPos(ScrW() / 2 - w / 2 + 1, ScrH() / 3 + 1)
	surface.DrawText(RespawnTime)
	surface.SetTextColor(color_white)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 3)
	surface.DrawText(RespawnTime)
	local Txt = BaseWars.LANG.RespawnIn
	local w2, h2 = surface.GetTextSize(Txt)
	surface.SetTextColor(color_black)
	surface.SetTextPos(ScrW() / 2 - w2 / 2 + 1, ScrH() / 3 - h2)
	surface.DrawText(Txt)
	surface.SetTextColor(color_white)
	surface.SetTextPos(ScrW() / 2 - w2 / 2, ScrH() / 3 - h2 - 1)
	surface.DrawText(Txt)
end

hook.Add("HUDPaint", tag .. ".Paint", Curry(MODULE.Paint))

local Red = Color(255, 0, 0, 255)
local Green = Color(0, 255, 0, 255)
function MODULE:PreDrawHalos()
	local Plys, Plys2 = {}, {}
	for _, p in next, player.GetAll() do
		if not p:Alive() then continue end
		local Karma = p:GetKarma()
		if Karma > BaseWars.Config.AntiRDM.KarmaGlowLevel then
			Plys[#Plys + 1] = p
		elseif Karma < -BaseWars.Config.AntiRDM.KarmaGlowLevel then
			Plys2[#Plys2 + 1] = p
		end
	end
	halo.Add(Plys, Green, 1, 1)
	halo.Add(Plys2, Red, 1, 1)
end

hook.Add("PreDrawHalos", tag .. ".PreDrawHalos", Curry(MODULE.PreDrawHalos))
