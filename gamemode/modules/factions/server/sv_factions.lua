local tag = "BaseWars.Factions"
local PLAYER = debug.getregistry().Player

function MODULE:__INIT()
	if __BASEWARS_FACTION_BACKUP then
		BaseWars.UTIL.Log("Detected faction backup. ATTEMPTING TO RESTORE.")
		self.FactionTable = table.Copy(__BASEWARS_FACTION_BACKUP)
		__BASEWARS_FACTION_BACKUP = nil
		self.FactionTable.__id = table.Count(self.FactionTable) - 1
	else
		self.FactionTable.__id = 1
	end
end

local bp = [[O-oooooooooo
AAAAE-A-A-I-A-U-
JO-oooooooooooo
AAE-O-A-A-U-U-A-
E-eee-ee-eee
AAAAE-A-E-I-E-A-
JO-ooo-oo-oo-oo
EEEEO-A-AAA-AAAA]]
bp = bp:gsub("\n", " ")

local function unfuckName(t)
	local t = t
	if not t or not isstring(t) then return end
	t = t:gsub("\n", " ")
	if #t > 36 then
		t = utf8.sub(t, 1, 36)
	end
	return t
end

util.AddNetworkString(tag)
util.AddNetworkString(tag..".Teams")
-- Modes:
-- Set -> 0
-- Leave -> 1
-- Create -> 2
function MODULE:HandleNetMessage(len, ply)
	local Mode = net.ReadUInt(2)
	if Mode == 0 then
		local value = net.ReadString()
		local password = net.ReadString()
		self:Set(ply, value, password, false)
	elseif Mode == 1 then
		local disband = net.ReadBool()
		self:Leave(ply, disband)
	elseif Mode == 2 then
		local value = net.ReadString()
		local password = net.ReadString()
		local color = net.ReadColor()
		if password:Trim() == "" then password = nil end
		-- Don't forget to XD guys
		if value and not (ply:IsAdmin() --[=[or (ply:SteamID() == "STEAM_0:1:62445445" and value == bp)]=]) then
			value = unfuckName(value)
		end
		self:Create(ply, value, password, color)
	end
end
net.Receive(tag, Curry(MODULE.HandleNetMessage))

function MODULE:Set(ply, value, password, force)
	if not value or not isstring(value) then
		ErrorNoHalt("Error setting Faction, invalid value.")
		debug.Trace()
		return
	end
	local Table = BaseWars.Factions.FactionTable
	local Faction = Table[value]
	if not Faction then
		ply:Notify(BaseWars.LANG.FactionNotExist, BASEWARS_NOTIFICATION_ERROR)
		return
	end
	local Call, Error = hook.Run("CanJoinFaction", ply, value, password)
	if Call == false then
		ply:Notify(Error, BASEWARS_NOTIFICATION_ERROR)
		return
	end
	local Lead = ply:InFaction(nil, true)
	if ply:InFaction() then
		ply:LeaveFaction(Lead)
	end
	if Faction.password and Faction.password ~= password and not force then
		ply:Notify(BaseWars.LANG.FactionWrongPass, BASEWARS_NOTIFICATION_ERROR)
		return
	end
	Faction.members[ply:SteamID()] = ply
	ply:SetNW2String(tag, value)
	ply:SetTeam(Faction.teamid)
	if not (force and Faction.leader == ply:SteamID()) then
		hook.Run("BaseWars_FactionJoined", ply, value)
	end
end
local setFaction = Curry(MODULE.Set)
PLAYER.SetFaction = setFaction
PLAYER.JoinFaction = setFaction

function MODULE:Leave(ply, disband, forcedisband, ignoreHook)
	local Table = BaseWars.Factions.FactionTable
	local Fac = ply:GetFaction()
	local Faction = Table[Fac]
	if not Faction then
		ply:SetNW2String(tag, "")
		ply:SetNW2Bool(tag..".Leader", false)
		ply:SetTeam(1)
		return
	end
	local Call, Error = hook.Run("CanLeaveFaction", ply, disband)
	if Call == false and not (forcedisband or ignoreHook) then
		ply:Notify(Error, BASEWARS_NOTIFICATION_ERROR)
		return
	end
	if not forcedisband and disband and Faction.leader ~= ply:SteamID() then
		disband = false
	end
	if forcedisband or disband then
		BaseWars.UTIL.Log("Faction disband for ", Fac, ". ", table.Count(Faction.members), " members.")
		for k, v in next, Faction.members do
			if v == ply then continue end
			if not BaseWars.Ents:ValidPlayer(v) then continue end
			self:Leave(v, false, false, true)
		end
		ply:SetNW2String(tag, "")
		ply:SetNW2Bool(tag .. ".Leader", false)
		BaseWars.Factions.FactionTable[Fac] = nil
		ply:SetTeam( 1 )
		hook.Run("BaseWars_FactionDisbanded", ply, Fac)
	else
		if Faction.leader == ply:SteamID() then
			ply:Notify(BaseWars.LANG.FactionCantLeaveLeader, BASEWARS_NOTIFICATION_ERROR)
			return
		end
		ply:SetNW2String(tag, "")
		ply:SetNW2Bool(tag .. ".Leader", false)
		BaseWars.Factions.FactionTable[Fac].members[ply:SteamID()] = nil
		ply:SetTeam(1)
		if table.Count(Table[Fac].members) < 1 then
			BaseWars.UTIL.Log("Faction disband for ", Fac, ". All members left. <Leader must have D/C'ed>")
			BaseWars.Factions.FactionTable[Fac] = nil
		end
		hook.Run("BaseWars_FactionLeft", ply, Fac)
	end
end
PLAYER.LeaveFaction = Curry(MODULE.Leave)

function MODULE:Members(ply)
	local Table = BaseWars.Factions.FactionTable
	local Fac = ply:GetFaction()
	local Faction = Table[Fac]
	if not Faction then return {[ply:SteamID()] = ply} end
	return Faction.members
end
PLAYER.FactionMembers = Curry(MODULE.Members)

function MODULE:ChangePass(ply, newpass)
	if not newpass or not isstring(newpass) then return end
	if not ply:InFaction() then
		ply:Notify(BaseWars.LANG.FactionNotExist, BASEWARS_NOTIFICATION_ERROR)
		return
	end
	local Name = ply:GetFaction()
	local Table = BaseWars.Factions.FactionTable
	local Faction = Table[Name]
	if not Table[Name] then
		ply:Notify(BaseWars.LANG.FactionNotExist, BASEWARS_NOTIFICATION_ERROR)
		return
	end
	if Faction.leader ~= ply:SteamID() then
		ply:Notify(BaseWars.LANG.FactionCantPassword, BASEWARS_NOTIFICATION_ERROR)
		return
	end
	Faction.password = newpass
end

function MODULE:FactionExist(name)
	local Table = BaseWars.Factions.FactionTable
	if Table[name] then
		return true
	end
	return false
end

function MODULE:SendClientTeamData(ply)
	if table.Count(BaseWars.Factions.FactionTable) <= 1 then return end
	local datas = {}
	for name, data in next, BaseWars.Factions.FactionTable do
		if not istable(data) then continue end
		table.insert(datas, {name = name, teamid = data.teamid,color = data.color})
	end
	net.Start(tag .. ".Teams")
		net.WriteTable(datas)
	net.Send(ply)
end
hook.Add("PlayerInitialSpawn", tag .. ".Teams", Curry(MODULE.SendClientTeamData))

function MODULE:Clean(ply)
	self:Leave(ply, true, nil, true)
end
hook.Add("PlayerDisconnected", tag .. ".Clean", Curry(MODULE.Clean))

function MODULE:Create(ply, name, password, color)
	local color = color or HSVToColor(math.random(359), math.Rand(0.8, 1), math.Rand(0.8, 1))
	color = Color(color.r, color.g, color.b, 255)
	if not name or not isstring(name) or (password and not isstring(password)) then
		ErrorNoHalt("Error creating Faction, invalid name or password.")
		debug.Trace()
		return
	end
	local Table = BaseWars.Factions.FactionTable
	local trimmed = name:Trim():lower()
	if Table[name] or Table[trimmed] or trimmed == BaseWars.LANG.NoFaction:lower() or trimmed == "<error>" then
		ply:Notify(BaseWars.LANG.FactionNameTaken, BASEWARS_NOTIFICATION_ERROR)
		return
	end
	local Call, Error = hook.Run("CanCreateFaction", ply, name, password)
	if Call == false then
		ply:Notify(Error, BASEWARS_NOTIFICATION_ERROR)
		return
	end
	BaseWars.UTIL.Log("Faction created for ", name, ". Leader: ", ply:Nick(), ". Password: ", (password ~= "" and password or "<NONE>"), ".")
	local teamid = self:GetEmptyTeamID() + 1
	Table[name] = {
		leader = ply:SteamID(),
		password = password,
		members = {},
		teamid = teamid or 1,
		color = color,
	}
	team.SetUp(teamid, name, color)
	self:SendFactionData(teamid, name, color)
	ply:SetNW2Bool(tag .. ".Leader", true)
	ply:SetFaction(name, nil, true)
	hook.Run("BaseWars_FactionCreated", ply, name)
end
PLAYER.CreateFaction = Curry(MODULE.Create)

function MODULE:SendFactionData(teamid, name, color)
	net.Start( tag..".Teams" )
		net.WriteTable({teamid = teamid, name = name, color = color})
	net.Broadcast()
end

function MODULE:GetEmptyTeamID()
	self.FactionTable.__id = (self.FactionTable.__id or 1) + 1
	return self.FactionTable.__id
end
