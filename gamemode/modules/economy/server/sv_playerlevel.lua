local tag = "BaseWars.PlayerLevel"
local Economy = MODULE.Class
local economy = MODULE
local PLAYER = debug.getregistry().Player

function Economy:InitLevel(ply)
	BaseWars.MySQL.InitPlayer(ply, "xp", "0")
	BaseWars.MySQL.InitPlayer(ply, "level", "1")
end
function PLAYER:InitLevel()
	economy:InitLevel(self)
end
for k, v in next, player.GetAll() do
	economy:InitLevel(v)
end
function Economy:SaveLevel(ply, amount)
	BaseWars.MySQL.SaveVar(ply, "level", amount or self:GetLevel(ply))
end
function Economy:SaveXP(ply, amount)
	BaseWars.MySQL.SaveVar(ply, "xp", amount or self:GetXP(ply))
end
function Economy:SaveLevels(ply)
	self:SaveLevel(ply)
	self:SaveXP(ply)
end
function PLAYER:SaveLevels()
	economy:SaveLevels(self)
end

function Economy:LoadLevels(ply)
	self:InitLevel(ply)
	BaseWars.MySQL.LoadVar(ply, "level", function(ply, var, val)
		if not IsValid(ply) then return end
		local val = tostring(val)
		ply:SetNWString(tag .. ".Level", val)
		ply.level = val
	end)
	BaseWars.MySQL.LoadVar(ply, "xp", function(ply, var, val)
		if not IsValid(ply) then return end
		local val = tostring(val)
		ply:SetNWString(tag .. ".XP", val)
		ply.xp = val
	end)
end
function PLAYER:LoadLevels()
	economy:LoadLevels(self)
end

function Economy:CheckLevels(ply)
	local neededxp = ply:GetXPNextLevel()
	if ply:GetXP() >= neededxp then
		if ply:GetLevel() == BaseWars.Config.LevelSettings.MaxLevel then
			ply:SetLevel( BaseWars.Config.LevelSettings.MaxLevel )
			ply:SetXP( 0 )
			return
		end
		ply:AddLevel(1)
		ply:SetXP( ply:GetXP() - neededxp)
	end
end
function Economy:SetLevel(ply, amount)
	if not isnumber(amount) or amount < 0 then amount = 0 end
	if amount > BaseWars.Config.LevelSettings.MaxLevel then amount = BaseWars.Config.LevelSettings.MaxLevel end
	amount = math.Round(amount)
	ply.level = amount
	self:SaveLevel(ply, amount)
	ply:SetNWString(tag .. ".Level", tostring(amount))
end
function PLAYER:SetLevel(amount)
	economy:SetLevel(self, amount)
end

function Economy:AddLevel(ply, amount)
	local Value = ply:GetLevel()
	ply:SetLevel(Value + amount)
end
function PLAYER:AddLevel(amount)
	economy:AddLevel(self, amount)
end

function Economy:SetXP(ply, amount)
	if not isnumber(amount) or amount < 0 then amount = 0 end
	amount = math.Round(amount)
	ply.xp = amount
	self:SaveXP(ply, amount)
	ply:SetNWString(tag .. ".XP", tostring(amount))
	self:CheckLevels( ply )
end
function PLAYER:SetXP(amount)
	economy:SetXP(self, amount)
end

function Economy:AddXP(ply, amount)
	local Value = ply:GetXP()
	ply:SetXP(Value + amount)
end
function PLAYER:AddXP(amount)
	economy:AddXP(self, amount)
end

hook.Add("LoadData", tag .. ".Load", function(ply)
	economy:LoadLevels(ply)
end)
hook.Add("PlayerDisconnected", tag .. ".Save", function(ply)
	economy:SaveLevels(ply)
end)
