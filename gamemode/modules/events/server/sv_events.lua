MODULE.Name 	= "Events"
MODULE.Author 	= "Q2F2 & Ghosty"

local tag = "BaseWars.Events"

if SERVER then
	function MODULE:CleanupMap()
		for k, v in next, ents.FindByClass("game_text") do
			SafeRemoveEntity(v)
		end
	end
	hook.Add("InitPostEntity", tag .. ".CleanupMap", Curry(MODULE.CleanupMap))
	hook.Add("PostCleanupMap", tag .. ".CleanupMap", Curry(MODULE.CleanupMap))
end
