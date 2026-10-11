local tag = "BaseWars.Money"
local Economy = MODULE.Class
local economy = MODULE
local PLAYER = debug.getregistry().Player

util.AddNetworkString(tag)

function Economy:SendMoney(ply)
	if not IsValid(ply) or not ply.BaseWarsMoneyReady or ply.BaseWarsMoney == nil then return end
	net.Start(tag)
		net.WriteDouble(ply.BaseWarsMoney)
	net.Send(ply)
end

function Economy:HandleSyncRequest(len, ply)
	if not IsValid(ply) then return end
	local now = CurTime()
	if ply.NextMoneySyncRequest and ply.NextMoneySyncRequest > now then return end
	ply.NextMoneySyncRequest = now + 1
	ply.BaseWarsMoneyReady = true
	self:SendMoney(ply)
end
net.Receive(tag, function(len, ply)
	economy:HandleSyncRequest(len, ply)
end)

function Economy:UpdateMoney(ply, amount)
	ply.BaseWarsMoney = amount
	self:SendMoney(ply)
end

function Economy:InitMoney(ply)
	BaseWars.MySQL.InitPlayer(ply, "money", tostring(BaseWars.Config.StartMoney))
end
function PLAYER:InitMoney()
	economy:InitMoney(self)
end

function Economy:SaveMoney(ply, amount)
	BaseWars.MySQL.SaveVar(ply, "money", amount or self:GetMoney(ply))
end
function PLAYER:SaveMoney(amount)
	economy:SaveMoney(self, amount)
end

function Economy:LoadMoney(ply)
	self:InitMoney(ply)
	BaseWars.MySQL.LoadVar(ply, "money", function(ply, var, val)
		if not IsValid(ply) then return end
		self:UpdateMoney(ply, tonumber(val) or 0)
	end)
end
function PLAYER:LoadMoney()
	economy:LoadMoney(self)
end

function Economy:SetMoney(ply, amount)
	local amount = tonumber(amount)
	if not isnumber(amount) or amount < 0 then amount = 0 end
	if amount ~= amount then amount = 0 end
	amount = math.Round(amount)
	self:SaveMoney(ply, amount)
	self:UpdateMoney(ply, amount)
end
function PLAYER:SetMoney(amount)
	economy:SetMoney(self, amount)
end

function Economy:GiveMoney(ply, amount)
	self:SetMoney(ply, self:GetMoney(ply) + amount)
end
function PLAYER:GiveMoney(amount)
	economy:GiveMoney(self, amount)
end

function Economy:TakeMoney(ply, amount)
	self:SetMoney(ply, self:GetMoney(ply) - amount)
end
function PLAYER:TakeMoney(amount)
	economy:TakeMoney(self, amount)
end

function Economy:TransferMoney(ply1, amount, ply2)
	self:TakeMoney(ply1, amount)
	self:GiveMoney(ply2, amount)
	hook.Run("BaseWars_MoneyTransferred", ply1, ply2, amount)
end
function PLAYER:TransferMoney(amount, recipient)
	economy:TransferMoney(self, amount, recipient)
end

hook.Add("LoadData", tag .. ".Load", function(ply)
	economy:LoadMoney(ply)
end)
hook.Add("PlayerDisconnected", tag .. ".Save", function(ply)
	if ply.BaseWarsMoney == nil then return end
	ply:SaveMoney()
end)

for _, ply in ipairs(player.GetAll()) do
	if ply.BaseWarsMoney == nil then economy:LoadMoney(ply) end
end
