local tag = "BaseWars.AFK"
local PLAYER = debug.getregistry().Player

util.AddNetworkString(tag)

function MODULE:HandleNetMessage(len, ply)
	local mode = net.ReadUInt(2)
	if mode == 0 then
		self:ClearAFK(ply)
	end
end
net.Receive(tag, Curry(MODULE.HandleNetMessage))

for _, ply in next, player.GetAll() do
	ply:SetNW2Int(tag, CurTime())
end

function MODULE:ClearAFK(ply)
	ply:SetNW2Int(tag, CurTime())
end
PLAYER.ClearAFK = Curry(MODULE.ClearAFK)

function MODULE:PlayerAuth(ply)
	self:ClearAFK(ply)
end
hook.Add("PlayerAuth", tag .. ".PlayerAuth", Curry(MODULE.PlayerAuth))

function MODULE:PlayerInitialSpawn(ply)
	ply:SetNW2Int(tag, CurTime())
end
hook.Add("PlayerInitialSpawn", tag .. ".PlayerInitialSpawn", Curry(MODULE.PlayerInitialSpawn))

local clear = Curry(MODULE.ClearAFK)
hook.Add("PlayerSay", tag, clear)
hook.Add("KeyPress", tag, clear)
