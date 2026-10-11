MODULE.Name 	= "NPCs"
MODULE.Author 	= "Q2F2 & Ghosty"

--for k, v in next, ents.FindByClass"bw_npc" do print("[" .. k .. "] = {") local a = v:GetAngles() local p = v:GetPos() local r = math.Round print("\tPos = Vector(" .. r(p.x) .. ", " .. r(p.y) .. ", " .. r(p.z) .. "),") print("\tAng = Angle(" .. r(a.p) .. ", " .. r(a.y) .. ", " .. r(a.r) .. "),")  print("},\n") end

local tag = "BaseWars.NPCs"
local PLAYER = debug.getregistry().Player


util.AddNetworkString("BaseWars.NPCs.Menu")

function MODULE:CreateNPCs()
	local Map = game.GetMap()
	local Entry = BaseWars.NPCTable[Map]
	if not Entry then return end
	for k, v in next, Entry do
		local Ent = ents.Create(v.Class or "bw_npc")
			if not BaseWars.Ents:Valid(Ent) then continue end
			Ent:SetPos(v.Pos)
			Ent:SetAngles(v.Ang)
		Ent:Spawn()
		Ent:Activate()
		BaseWars.CPPI.SetOwner(Ent, game.GetWorld())
	end
end
hook.Add("InitPostEntity", tag .. ".CreateNPCs", Curry(MODULE.CreateNPCs))
