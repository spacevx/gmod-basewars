local tag = "BaseWars.Money"

net.Receive(tag, function()
	local amount = net.ReadDouble()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	ply.BaseWarsMoney = amount
end)

local function requestMoney()
	if not IsValid(LocalPlayer()) then return end
	net.Start(tag)
	net.SendToServer()
end

hook.Add("InitPostEntity", tag .. ".Ready", requestMoney)

if IsValid(LocalPlayer()) then
	timer.Simple(0, requestMoney)
end
