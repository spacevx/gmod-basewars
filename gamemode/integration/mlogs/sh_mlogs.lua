if not file.Exists("mlogs/config/sh_config.lua", "LUA") then return end

local category = "basewars"
local translations = {
	ENGLISH = {
		MLogsPurchases = "Purchases",
		MLogsPrinters = "Printer collections",
		MLogsRaidStarts = "Raid starts",
		MLogsRaidEnds = "Raid ends",
		MLogsFactions = "Factions",
		MLogsTransfers = "Money transfers",
		MLogsLevels = "Levels",
		MLogsKarma = "Karma losses",
		MLogsPurchase = "^player1 purchased ^item for ^amount",
		MLogsPrinter = "^player1 collected ^amount from ^item",
		MLogsRaidStart = "^player1 started a raid against ^player2",
		MLogsRaidEnd = "The raid between ^player1 and ^player2 ended",
		MLogsFaction = "^player1 ^action faction ^faction",
		MLogsTransfer = "^player1 transferred ^amount to ^player2",
		MLogsLevel = "^player1 changed level from ^old to ^new",
		MLogsKarmaLoss = "^player1 lost ^amount karma and now has ^new",
		MLogsFactionCreated = "created",
		MLogsFactionJoined = "joined",
		MLogsFactionLeft = "left",
		MLogsFactionDisbanded = "disbanded",
	},
	FRENCH = {
		MLogsPurchases = "Achats",
		MLogsPrinters = "Collectes des imprimantes",
		MLogsRaidStarts = "Débuts de raid",
		MLogsRaidEnds = "Fins de raid",
		MLogsFactions = "Factions",
		MLogsTransfers = "Transferts d'argent",
		MLogsLevels = "Niveaux",
		MLogsKarma = "Pertes de karma",
		MLogsPurchase = "^player1 a acheté ^item pour ^amount",
		MLogsPrinter = "^player1 a collecté ^amount depuis ^item",
		MLogsRaidStart = "^player1 a lancé un raid contre ^player2",
		MLogsRaidEnd = "Le raid entre ^player1 et ^player2 est terminé",
		MLogsFaction = "^player1 a ^action la faction ^faction",
		MLogsTransfer = "^player1 a transféré ^amount à ^player2",
		MLogsLevel = "^player1 a changé de niveau de ^old à ^new",
		MLogsKarmaLoss = "^player1 a perdu ^amount karma et en a maintenant ^new",
		MLogsFactionCreated = "créé",
		MLogsFactionJoined = "rejoint",
		MLogsFactionLeft = "quitté",
		MLogsFactionDisbanded = "dissous",
	},
}

for language, lookup in pairs(BaseWars.LANG.__LANGUAGELOOK) do
	local localized = translations[language] or translations.ENGLISH
	for key, fallback in pairs(translations.ENGLISH) do
		lookup[key] = localized[key] or fallback
	end
end

local definitions = {
	purchases = "MLogsPurchase",
	printers = "MLogsPrinter",
	raidstart = "MLogsRaidStart",
	raidend = "MLogsRaidEnd",
	factions = "MLogsFaction",
	transfers = "MLogsTransfer",
	levels = "MLogsLevel",
	karma = "MLogsKarmaLoss",
}

local function canRegister()
	if not mLogs or not isfunction(mLogs.addCategory) or not isfunction(mLogs.addCategoryDefinitions)
		or not isfunction(mLogs.doLogReplace) then return false end
	if CLIENT then return true end
	return isfunction(mLogs.addLogger) and isfunction(mLogs.addHook) and isfunction(mLogs.log)
		and mLogs.logger and isfunction(mLogs.logger.getPlayerData) and isfunction(mLogs.logger.getEntityData)
end

local function register()
	if not canRegister() then return false end
	if BaseWars.MLogsRegistered == mLogs.addCategory then return true end

	mLogs.addCategory("BaseWars", category, Color(255, 174, 64), function()
		return BaseWars ~= nil
	end, true)

	local formatters = {}
	for logger, key in pairs(definitions) do
		local localeKey = key
		formatters[logger] = function(data)
			return mLogs.doLogReplace(string.Explode(" ", BaseWars.LANG[localeKey]), data)
		end
	end
	mLogs.addCategoryDefinitions(category, formatters)

	if SERVER then
		local function money(amount)
			return BaseWars.LANG.CURRENCY .. BaseWars.NumberFormat(tonumber(amount) or 0)
		end

		local function person(ply)
			return mLogs.logger.getPlayerData(ply)
		end

		local function log(logger, data)
			mLogs.log(logger, category, data)
		end

		mLogs.addLogger(BaseWars.LANG.MLogsPurchases, "purchases", category)
		mLogs.addLogger(BaseWars.LANG.MLogsPrinters, "printers", category)
		mLogs.addLogger(BaseWars.LANG.MLogsRaidStarts, "raidstart", category)
		mLogs.addLogger(BaseWars.LANG.MLogsRaidEnds, "raidend", category)
		mLogs.addLogger(BaseWars.LANG.MLogsFactions, "factions", category)
		mLogs.addLogger(BaseWars.LANG.MLogsTransfers, "transfers", category)
		mLogs.addLogger(BaseWars.LANG.MLogsLevels, "levels", category)
		mLogs.addLogger(BaseWars.LANG.MLogsKarma, "karma", category)

		local function purchase(ply, ent, price, itemName)
			if not IsValid(ply) or not IsValid(ent) then return end
			log("purchases", {player1 = person(ply), item = mLogs.logger.getEntityData(ent, {name = itemName}), amount = money(price)})
		end
		for _, event in ipairs({"BaseWars_PlayerBuyEntity", "BaseWars_PlayerBuyProp", "BaseWars_PlayerBuyGun", "BaseWars_PlayerBuyDrug"}) do
			mLogs.addHook(event, category, purchase)
		end

		mLogs.addHook("BaseWars_PlayerEmptyPrinter", category, function(ply, ent, amount)
			if not IsValid(ply) or not IsValid(ent) or not isnumber(amount) or amount <= 0 then return end
			log("printers", {player1 = person(ply), item = mLogs.logger.getEntityData(ent), amount = money(amount)})
		end)

		local function raid(logger, ply, target)
			if not IsValid(ply) or not IsValid(target) then return end
			log(logger, {player1 = person(ply), player2 = person(target)})
		end
		mLogs.addHook("RaidStart", category, function(ply, target)
			raid("raidstart", ply, target)
		end)
		mLogs.addHook("RaidEnded", category, function()
			local state = BaseWars.Raid.State
			raid("raidend", state.Participant1, state.Participant2)
		end)

		local factionEvents = {
			BaseWars_FactionCreated = "MLogsFactionCreated",
			BaseWars_FactionJoined = "MLogsFactionJoined",
			BaseWars_FactionLeft = "MLogsFactionLeft",
			BaseWars_FactionDisbanded = "MLogsFactionDisbanded",
		}
		for event, action in pairs(factionEvents) do
			local actionKey = action
			mLogs.addHook(event, category, function(ply, faction)
				if not IsValid(ply) then return end
				log("factions", {player1 = person(ply), action = BaseWars.LANG[actionKey], faction = faction})
			end)
		end

		mLogs.addHook("BaseWars_MoneyTransferred", category, function(sender, recipient, amount)
			if not IsValid(sender) or not IsValid(recipient) or not isnumber(amount) or amount <= 0 or amount ~= amount then return end
			log("transfers", {player1 = person(sender), player2 = person(recipient), amount = money(amount)})
		end)
		mLogs.addHook("BaseWars_PlayerLevelChanged", category, function(ply, old, new)
			if not IsValid(ply) then return end
			log("levels", {player1 = person(ply), old = tostring(old), new = tostring(new)})
		end)
		mLogs.addHook("BaseWars_KarmaChanged", category, function(ply, old, new)
			if not IsValid(ply) or new >= old then return end
			log("karma", {player1 = person(ply), amount = tostring(old - new), new = tostring(new)})
		end)
	end

	BaseWars.MLogsRegistered = mLogs.addCategory
	return true
end

hook.Add("mLogs_ConfigLoaded", "BaseWars.mLogs.Register", register)
timer.Create("BaseWars.mLogs.Register", 1, 0, function()
	if register() then timer.Remove("BaseWars.mLogs.Register") end
end)
register()
