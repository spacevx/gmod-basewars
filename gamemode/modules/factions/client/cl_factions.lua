local tag = "BaseWars.Factions"
local PLAYER = debug.getregistry().Player

function MODULE:ReadTeams()
	local tbl = net.ReadTable()
	if type(tbl[1]) == "table" then
		for _, tbl2 in next, tbl do
			local teamid = tbl2.teamid
			local name = tbl2.name
			local color = tbl2.color
			team.SetUp(teamid, name, color)
		end
	else
		local teamid = tbl.teamid
		local name = tbl.name
		local color = tbl.color
		if not teamid or not name or not color then
			ErrorNoHalt("Error making team -> ", teamid, name, color)
		return end
		team.SetUp(teamid, name, color)
	end
end
net.Receive(tag .. ".Teams", Curry(MODULE.ReadTeams))

function MODULE:Set(ply, value, password, force)
	if not value or not isstring(value) then return end
	net.Start(tag)
		net.WriteUInt(0, 2)
		net.WriteString(value)
		net.WriteString(password or "")
	net.SendToServer()
end
local setFaction = Curry(MODULE.Set)
PLAYER.SetFaction = setFaction
PLAYER.JoinFaction = setFaction

function MODULE:Leave(ply, disband)
	net.Start(tag)
		net.WriteUInt(1, 2)
		net.WriteBool(disband)
	net.SendToServer()
end
PLAYER.LeaveFaction = Curry(MODULE.Leave)

function MODULE:ChangePass(ply, newpass)
	if not newpass or not isstring(newpass) then return end
end

function MODULE:Create(ply, name, password, color)
	local color = color or HSVToColor(math.random(359), math.Rand(0.8, 1), math.Rand(0.8, 1))
	color = Color(color.r, color.g, color.b, 255)
	if not name or not isstring(name) or (password and not isstring(password)) then return end
	net.Start(tag)
		net.WriteUInt(2, 2)
		net.WriteString(name)
		net.WriteString(password or "")
		net.WriteColor(color)
	net.SendToServer()
end
PLAYER.CreateFaction = Curry(MODULE.Create)
