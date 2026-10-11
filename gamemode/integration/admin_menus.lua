BaseWars.AdminMenus = BaseWars.AdminMenus or {}
local AdminMenus = BaseWars.AdminMenus

AdminMenus.Providers = {}
AdminMenus.Active = nil

function AdminMenus:Register(name, path, available)
	self.Providers[#self.Providers + 1] = {
		Name = name,
		Path = path,
		Available = available,
	}
	if SERVER then AddCSLuaFile(path) end
end

function AdminMenus:Load()
	local selected
	for _, provider in ipairs(self.Providers) do
		if provider.Available() then
			if selected then
				error("BaseWars cannot run with multiple admin menus installed. Keep only one admin menu installed.", 0)
			end
			selected = provider
		end
	end
	if not selected or self.Active then return end
	include(selected.Path)
	self.Active = selected.Name
end

function AdminMenus:HasActive()
	return self.Active ~= nil
end

AdminMenus:Register("sam", "integration/sam/bw_admin_sam.lua", function()
	return sam and sam.command and sam.command.new and sam.player and sam.player.send_message
end)

AdminMenus:Register("ulx", "integration/ulx/bw_admin_ulx.lua", function()
	return ulx and ulx.command and ULib and ULib.cmds
end)

hook.Add("PostGamemodeLoaded", "BaseWars.AdminMenus", function()
	AdminMenus:Load()
end)

timer.Simple(0, function()
	AdminMenus:Load()
end)
