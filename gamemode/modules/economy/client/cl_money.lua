local tag = "BaseWars.Money"
local Economy = MODULE.Class
local economy = MODULE

function Economy:ReceiveMoney()
	local amount = net.ReadDouble()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	ply.BaseWarsMoney = amount
end

function Economy:RequestMoney()
	if not IsValid(LocalPlayer()) then return end
	net.Start(tag)
	net.SendToServer()
end

net.Receive(tag, function()
	economy:ReceiveMoney()
end)

hook.Add("InitPostEntity", tag .. ".Ready", function()
	economy:RequestMoney()
end)

if IsValid(LocalPlayer()) then
	timer.Simple(0, function()
		economy:RequestMoney()
	end)
end
