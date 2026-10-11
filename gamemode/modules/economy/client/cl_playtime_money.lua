local tag = "BaseWars.PlayTime_Money"
local economy = MODULE
local Economy = MODULE.Class

local HUD = {}
HUD.__index = HUD

local white = Color(255, 255, 255, 150)
local shade = Color(0, 0, 0, 140)
local green = Color(42, 255, 0)
local red = Color(255, 0, 0)

surface.CreateFont(tag, {
	font = "Roboto",
	weight = 800,
	size = 24,
})

local function playTime(time)
	local str = ""
	if time.h > 0 then str = str .. time.h .. BaseWars.LANG.HoursShort .. " " end
	if time.m > 0 then str = str .. time.m .. BaseWars.LANG.MinutesShort .. " " end
	if time.s > 0 then str = str .. time.s .. BaseWars.LANG.SecondsShort .. " " end
	return #str > 0 and str or "0s"
end

function HUD.new()
	return setmetatable({
		player = LocalPlayer(),
		timeMaterial = Material("icon32/clock_wh32.png", "nocull noclamp smooth"),
		moneyMaterial = Material("icon32/money_wh32.png", "nocull noclamp smooth"),
		previousMoney = 0,
		lastChange = CurTime(),
		loss = false,
		effects = {},
		materialRetry = true,
	}, HUD)
end

function HUD:AddEffect(amount)
	local endTime = self.lastChange
	local color = amount < 0 and red or green
	local x, y = 106, ScrH() - 73
	local change = 4
	self.effects[#self.effects + 1] = function()
		local alpha = math.Clamp(endTime - CurTime(), 0, 1) * 150
		if alpha <= 0.01 then return false end
		change = change / 1.08
		draw.DrawText(
			(amount > 0 and "+ " or " ") .. BaseWars.LANG.CURRENCY .. BaseWars.NumberFormat(amount),
			tag, x, y, ColorAlpha(color, alpha), TEXT_ALIGN_LEFT
		)
		y = y + change
		return true
	end
end

function HUD:DrawEffects()
	for i = #self.effects, 1, -1 do
		if not self.effects[i]() then table.remove(self.effects, i) end
	end
end

function HUD:RefreshMaterials()
	if not self.materialRetry or (not self.timeMaterial:IsError() and not self.moneyMaterial:IsError()) then return end
	self.timeMaterial = Material("icon32/clock_wh32.png", "nocull noclamp smooth")
	self.moneyMaterial = Material("icon32/money_wh32.png", "nocull noclamp smooth")
	self.materialRetry = false
	timer.Simple(3, function()
		self.materialRetry = true
	end)
end

function HUD:Paint()
	if not IsValid(self.player) then
		self.player = LocalPlayer()
		return
	end

	local height = ScrH()
	local now = CurTime()
	local time = self.player.GetPlayTimeTable and self.player:GetPlayTimeTable() or {h = 0, m = 0, s = 0}
	local money = self.player.GetMoney and self.player:GetMoney() or 0
	if money ~= self.previousMoney then
		self.loss = money < self.previousMoney
		self.lastChange = now + 1
		self:AddEffect(money - self.previousMoney)
	end
	self.previousMoney = money

	surface.SetDrawColor(0, 0, 0, 150)
	surface.SetMaterial(self.timeMaterial)
	surface.DrawTexturedRect(66, height - 110, 32, 32)
	surface.SetDrawColor(255, 255, 255, 150)
	surface.DrawTexturedRect(64, height - 112, 32, 32)
	draw.DrawText(playTime(time), tag, 108, height - 106, shade, TEXT_ALIGN_LEFT)
	draw.DrawText(playTime(time), tag, 106, height - 108, white, TEXT_ALIGN_LEFT)

	surface.SetDrawColor(0, 0, 0, 150)
	surface.SetMaterial(self.moneyMaterial)
	surface.DrawTexturedRect(66, height - 70, 32, 32)
	surface.SetDrawColor(255, 255, 255, 150)
	surface.DrawTexturedRect(64, height - 72, 32, 32)
	local hue = self.loss and 0 or 110
	local moneyColor = ColorAlpha(HSVToColor(hue, 1 - math.Clamp(now - self.lastChange, 0, 1), 1), 150)
	local label = string.format(BaseWars.LANG.CURFORMER, BaseWars.NumberFormat(money))
	draw.DrawText(label, tag, 108, height - 66, shade, TEXT_ALIGN_LEFT)
	draw.DrawText(label, tag, 106, height - 68, moneyColor, TEXT_ALIGN_LEFT)
	self:DrawEffects()
	self:RefreshMaterials()
end

economy.HUD = HUD.new()
function Economy:Paint()
	return self.HUD:Paint()
end

hook.Add("HUDPaint", tag .. ".Paint", function()
	economy:Paint()
end)
