local BW = BaseWars

local colorRed 		= Color(255, 0, 0)
local colorBlue 	= Color(0, 0, 255)
local colorGreen 	= Color(0, 255, 0)
local colorWhite 	= Color(255, 255, 255)

local function Log(...)
	MsgC(SERVER and colorRed or colorBlue, "[BWML] ", colorWhite, ...)
	MsgN("")
end

if not BW then -- Woah, no BaseWars table? This should be loaded AFTER the table's created!
	Log("No BaseWars table??")
	return
end

if SERVER and not BW.UTIL then -- Woah, no UTIL table? This should be loaded AFTER the table's created!
	Log("No BaseWars.UITL table??")
	return
end

local ModuleLoader = {}
local fileFind = file.Find

local function findEntries(folder)
	local GMFolder = (GM or GAMEMODE).Folder or "basewars"
	local files, folders = fileFind(GMFolder:gsub("gamemodes/", "") .. "/gamemode/" .. folder .. "/*", "LUA")
	if not files or (#files == 0 and (not folders or #folders == 0)) then
		files, folders = fileFind(folder .. "/*", "LUA")
	end
	return files or {}, folders or {}
end

function ModuleLoader:IterateFiles(folder)
	local files = findEntries(folder)
	table.sort(files)
	local newFiles = {}
	for _, fileName in ipairs(files) do
		if fileName:sub(-4) == ".lua" then
			newFiles[#newFiles + 1] = folder .. "/" .. fileName
		end
	end
	local i = 0
	local function iter()
		i = i + 1
		return newFiles[i]
	end
	return iter
end

function ModuleLoader:GetFolders(folder)
	local _, folders = findEntries(folder)
	table.sort(folders)
	return folders
end

local getFn = string.GetFileFromFilename

local function loadModule()
	BW[MODULE.Name] = MODULE
	if MODULE.__INIT then
		BW[MODULE.Name]:__INIT()
	end
end

local function includeModule(fName)
	local ok, err = pcall(include, fName)
	if not ok then
		local name = MODULE.Name or getFn(fName)
		Log("There was an error loading the module ", colorGreen, "\"", name, "\"", colorWhite, ".",
			"The error is:\n", err)
		return false
	end
	return true
end

function ModuleLoader:Load()
	local oldTime = SysTime()
	local moduleCount = 0
	for _, moduleFolder in ipairs(self:GetFolders("modules")) do
		MODULE = {}
		local module = MODULE
		function Curry(f)
			return function(...)
				return f(module, ...)
			end
		end
		local modulePath = "modules/" .. moduleFolder
		local loaded = false
		local failed = false
		local function loadFiles(realm)
			for fName in self:IterateFiles(modulePath .. "/" .. realm) do
				if SERVER and realm == "shared" then
					AddCSLuaFile(fName)
				end
				loaded = true
				if not includeModule(fName) then
					failed = true
				end
			end
		end
		loadFiles("shared")
		if SERVER then
			loadFiles("server")
			for fName in self:IterateFiles(modulePath .. "/client") do
				AddCSLuaFile(fName)
			end
		else
			loadFiles("client")
		end
		if loaded and not failed then
			if MODULE.Name then
				loadModule()
				moduleCount = moduleCount + 1
			else
				Log("Module with empty name: ", moduleFolder, ", ignoring.")
			end
		end
	end
	MODULE = nil
	Curry = nil
	local newTime = SysTime()
	Log("STATS: Loaded ", tostring(moduleCount), " modules in ", tostring(math.Round(newTime - oldTime, 5)), " seconds.")
end

BW.ModuleLoader = ModuleLoader
