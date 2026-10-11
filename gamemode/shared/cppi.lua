local PLAYER = debug.getregistry().Player
local ENTITY = debug.getregistry().Entity

BaseWars.CPPI = BaseWars.CPPI or {}
local ownership = BaseWars.CPPI
ownership.Assigned = ownership.Assigned or setmetatable({}, {__mode = "k"})
ownership.Providers = ownership.Providers or {}
ownership.ProviderNames = ownership.ProviderNames or {}

function ownership.RegisterProvider(name, provider)
	if not ownership.Providers[name] then
		ownership.ProviderNames[#ownership.ProviderNames + 1] = name
	end
	ownership.Providers[name] = provider
end

function ownership.GetProvider()
	for _, name in ipairs(ownership.ProviderNames) do
		local provider = ownership.Providers[name]
		if provider:IsAvailable() then
			if provider.Sync then provider:Sync(ownership.Assigned) end
			return provider
		end
	end
end

function ownership.HasIndexedOwners()
	local provider = ownership.GetProvider()
	return provider and provider.ForEachOwned ~= nil
end

function ownership.SetOwner(ent, ply)
	if not IsValid(ent) or not ply then return end
	local provider = ownership.GetProvider()
	if provider then
		provider:SetOwner(ent, ply)
	else
		if ent.CPPISetOwner then ent:CPPISetOwner(ply) end
	end
	if IsValid(ply) and ply:IsPlayer() then ownership.Assigned[ent] = ply end
end

function ownership.GetOwner(ent)
	if not IsValid(ent) then return end
	local provider = ownership.GetProvider()
	if provider then return provider:GetOwner(ent) end
	if ent.CPPIGetOwner then
		local owner = ent:CPPIGetOwner()
		if IsValid(owner) then return owner end
	end
end

function ownership.ForEachOwned(ply, callback)
	local provider = ownership.GetProvider()
	if provider and provider.ForEachOwned then return provider:ForEachOwned(ply, callback) end
	for _, ent in ipairs(ents.GetAll()) do
		local owner = ownership.GetOwner(ent)
		if IsValid(owner) and owner:IsPlayer() and (not ply or owner == ply) and callback(ent, owner) == false then return end
	end
end

if CPPI then return end

CPPI                     = {}
local fallbackCPPI = CPPI
CPPI.CPPI_DEFER          = 100100
CPPI.CPPI_NOTIMPLEMENTED = 7080

if SERVER then
	function ENTITY:CPPISetOwner(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end
	function ENTITY:CPPISetOwnerUID(uid)
		return CPPI.CPPI_NOTIMPLEMENTED
	end
	function ENTITY:CPPICanTool(ply, tool)
		return CPPI.CPPI_NOTIMPLEMENTED
	end
	function ENTITY:CPPICanPhysgun(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end
	function ENTITY:CPPICanPickup(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end
	function ENTITY:CPPICanPunt(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end
end

function CPPI:GetName()
	return "BaseWars"
end

function CPPI:GetVersion()
	return CPPI.CPPI_NOTIMPLEMENTED
end

function CPPI:GetInterfaceVersion()
	return CPPI.CPPI_NOTIMPLEMENTED
end

function CPPI:GetNameFromUID(uid)
	return CPPI.CPPI_NOTIMPLEMENTED
end

function PLAYER:CPPIGetFriends()
	return CPPI.CPPI_NOTIMPLEMENTED
end

function ENTITY:CPPIGetOwner()
	return NULL, CPPI.CPPI_NOTIMPLEMENTED
end

if SERVER then
	timer.Simple(0, function()
		if CPPI ~= fallbackCPPI then return end
		for _, name in ipairs(ownership.ProviderNames) do
			local provider = ownership.Providers[name]
			if provider.IsInstalled and provider:IsInstalled() then return end
		end
		ErrorNoHalt("BaseWars requires a CPPI-compliant prop protection addon. We recommend gProtect: https://www.gmodstore.com/market/view/gprotect-prop-protection\n")
	end)
end
