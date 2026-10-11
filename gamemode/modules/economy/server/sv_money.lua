local tag = "BaseWars.Money"
local PLAYER = debug.getregistry().Player

util.AddNetworkString(tag)

function MODULE:SendMoney(ply)
	if not IsValid(ply) or not ply.BaseWarsMoneyReady or ply.BaseWarsMoney == nil then return end
	net.Start(tag)
		net.WriteDouble(ply.BaseWarsMoney)
	net.Send(ply)
end

function MODULE:HandleSyncRequest(len, ply)
	if not IsValid(ply) then return end
	local now = CurTime()
	if ply.NextMoneySyncRequest and ply.NextMoneySyncRequest > now then return end
	ply.NextMoneySyncRequest = now + 1
	ply.BaseWarsMoneyReady = true
	self:SendMoney(ply)
end
net.Receive(tag, Curry(MODULE.HandleSyncRequest))

function MODULE:UpdateMoney(ply, amount)
	ply.BaseWarsMoney = amount
	self:SendMoney(ply)
end

function MODULE:InitMoney(ply)
	BaseWars.MySQL.InitPlayer(ply, "money", tostring(BaseWars.Config.StartMoney))
end
PLAYER.InitMoney = Curry(MODULE.InitMoney)
function MODULE:SaveMoney(ply, amount)
	BaseWars.MySQL.SaveVar(ply, "money", amount or self:GetMoney(ply))
end
PLAYER.SaveMoney = Curry(MODULE.SaveMoney)
function MODULE:LoadMoney(ply)
	self:InitMoney(ply)
	BaseWars.MySQL.LoadVar(ply, "money", function(ply, var, val)
		if not IsValid(ply) then return end
		self:UpdateMoney(ply, tonumber(val) or 0)
	end)
end
PLAYER.LoadMoney = Curry(MODULE.LoadMoney)
function MODULE:SetMoney(ply, amount)
	local amount = tonumber(amount)
	if not isnumber(amount) or amount < 0 then amount = 0 end
	if amount ~= amount then amount = 0 end
	amount = math.Round(amount)
	self:SaveMoney(ply, amount)
	self:UpdateMoney(ply, amount)
end
PLAYER.SetMoney = Curry(MODULE.SetMoney)
function MODULE:GiveMoney(ply, amount)
	self:SetMoney(ply, self:GetMoney(ply) + amount)
end
PLAYER.GiveMoney = Curry(MODULE.GiveMoney)
function MODULE:TakeMoney(ply, amount)
	self:SetMoney(ply, self:GetMoney(ply) - amount)
end
PLAYER.TakeMoney = Curry(MODULE.TakeMoney)
function MODULE:TransferMoney(ply1, amount, ply2)
	self:TakeMoney(ply1, amount)
	self:GiveMoney(ply2, amount)
end
PLAYER.TransferMoney = Curry(MODULE.TransferMoney)
hook.Add("LoadData", tag .. ".Load", Curry(MODULE.LoadMoney))
hook.Add("PlayerDisconnected", tag .. ".Save", function(ply)
	if ply.BaseWarsMoney == nil then return end
	ply:SaveMoney()
end)

for _, ply in ipairs(player.GetAll()) do
	if ply.BaseWarsMoney == nil then MODULE:LoadMoney(ply) end
end
