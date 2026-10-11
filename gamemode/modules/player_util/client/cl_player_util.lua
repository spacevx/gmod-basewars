local tag = "BaseWars.Util_Player"
local PLAYER = debug.getregistry().Player

function MODULE:HandleNetMessage()
	local mode = net.ReadUInt(1)
	if mode == 0 then
		local text = net.ReadString()
		local col = net.ReadColor()
		self:Notification(LocalPlayer(), text, col)
	end
end
net.Receive(tag, Curry(MODULE.HandleNetMessage))

function MODULE:Notification(ply, text, col)
	MsgC(col, text, "\n")
	BaseWars.Notify:Add(text, col)
end
local notification = Curry(MODULE.Notification)
Notify = notification
PLAYER.Notify = notification
