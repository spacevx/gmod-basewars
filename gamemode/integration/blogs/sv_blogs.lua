if not file.Exists("gmodadminsuite/modules/logging/sh_init.lua", "LUA") then return end

local translations = {
	ENGLISH = {
		BLogsPurchase = "%s purchased %s for %s",
		BLogsPrinter = "%s collected %s from %s",
		BLogsRaidStart = "%s started a raid against %s",
		BLogsRaidEnd = "The raid between %s and %s ended",
		BLogsFaction = "%s %s faction %s",
		BLogsTransfer = "%s transferred %s to %s",
		BLogsLevel = "%s changed level from %s to %s",
		BLogsKarmaLoss = "%s lost %s karma and now has %s",
		BLogsFactionCreated = "created",
		BLogsFactionJoined = "joined",
		BLogsFactionLeft = "left",
		BLogsFactionDisbanded = "disbanded",
	},
	FRENCH = {
		BLogsPurchase = "%s a acheté %s pour %s",
		BLogsPrinter = "%s a collecté %s depuis %s",
		BLogsRaidStart = "%s a lancé un raid contre %s",
		BLogsRaidEnd = "Le raid entre %s et %s est terminé",
		BLogsFaction = "%s a %s la faction %s",
		BLogsTransfer = "%s a transféré %s à %s",
		BLogsLevel = "%s a changé de niveau de %s à %s",
		BLogsKarmaLoss = "%s a perdu %s karma et en a maintenant %s",
		BLogsFactionCreated = "créé",
		BLogsFactionJoined = "rejoint",
		BLogsFactionLeft = "quitté",
		BLogsFactionDisbanded = "dissous",
	},
}

for language, lookup in pairs(BaseWars.LANG.__LANGUAGELOOK) do
	local localized = translations[language] or translations.ENGLISH
	for key, fallback in pairs(translations.ENGLISH) do
		lookup[key] = localized[key] or fallback
	end
end

local function register()
	if not GAS or not GAS.Logging or not GAS.Logging.Loaded
		or not isfunction(GAS.Logging.MODULE) or not isfunction(GAS.Logging.AddModule) then return end
	if BaseWars.BLogsRegistered == GAS.Logging then return end

	local logging = GAS.Logging
	local function addModule(name, setup)
		local module = logging:MODULE()
		module.Category = "BaseWars"
		module.Name = name
		module.Colour = Color(255, 174, 64)
		module:Setup(function()
			setup(module)
		end)
		logging:AddModule(module)
	end

	local function playerToken(ply)
		return logging:FormatPlayer(ply)
	end

	local function moneyToken(amount)
		return logging:FormatMoney(amount)
	end

	addModule("Purchases", function(module)
		local function purchase(ply, ent, price, itemName)
			if not IsValid(ply) or not IsValid(ent) then return end
			module:Log(string.format(BaseWars.LANG.BLogsPurchase,
				playerToken(ply), logging:Highlight(itemName or ent:GetClass()), moneyToken(price)))
		end
		-- Prop purchases also fire BaseWars_PlayerBuyEntity.
		for _, event in ipairs({"BaseWars_PlayerBuyEntity", "BaseWars_PlayerBuyGun", "BaseWars_PlayerBuyDrug"}) do
			module:Hook(event, "basewars_blogs_purchase_" .. event, purchase)
		end
	end)

	addModule("Printer collections", function(module)
		module:Hook("BaseWars_PlayerEmptyPrinter", "basewars_blogs_printer", function(ply, ent, amount)
			if not IsValid(ply) or not IsValid(ent) or not isnumber(amount) or amount <= 0 then return end
			module:Log(string.format(BaseWars.LANG.BLogsPrinter,
				playerToken(ply), moneyToken(amount), logging:FormatEntity(ent)))
		end)
	end)

	addModule("Raid starts", function(module)
		module:Hook("RaidStart", "basewars_blogs_raid_start", function(ply, target)
			if not IsValid(ply) or not IsValid(target) then return end
			module:Log(string.format(BaseWars.LANG.BLogsRaidStart, playerToken(ply), playerToken(target)))
		end)
	end)

	addModule("Raid ends", function(module)
		module:Hook("RaidEnded", "basewars_blogs_raid_end", function()
			local state = BaseWars.Raid.State
			if not IsValid(state.Participant1) or not IsValid(state.Participant2) then return end
			module:Log(string.format(BaseWars.LANG.BLogsRaidEnd,
				playerToken(state.Participant1), playerToken(state.Participant2)))
		end)
	end)

	addModule("Factions", function(module)
		local events = {
			BaseWars_FactionCreated = "BLogsFactionCreated",
			BaseWars_FactionJoined = "BLogsFactionJoined",
			BaseWars_FactionLeft = "BLogsFactionLeft",
			BaseWars_FactionDisbanded = "BLogsFactionDisbanded",
		}
		for event, action in pairs(events) do
			local actionKey = action
			module:Hook(event, "basewars_blogs_faction_" .. event, function(ply, faction)
				if not IsValid(ply) then return end
				module:Log(string.format(BaseWars.LANG.BLogsFaction,
					playerToken(ply), BaseWars.LANG[actionKey], logging:Highlight(faction)))
			end)
		end
	end)

	addModule("Money transfers", function(module)
		module:Hook("BaseWars_MoneyTransferred", "basewars_blogs_transfer", function(sender, recipient, amount)
			if not IsValid(sender) or not IsValid(recipient) or not isnumber(amount) or amount <= 0 or amount ~= amount then return end
			module:Log(string.format(BaseWars.LANG.BLogsTransfer,
				playerToken(sender), moneyToken(amount), playerToken(recipient)))
		end)
	end)

	addModule("Levels", function(module)
		module:Hook("BaseWars_PlayerLevelChanged", "basewars_blogs_level", function(ply, old, new)
			if not IsValid(ply) then return end
			module:Log(string.format(BaseWars.LANG.BLogsLevel,
				playerToken(ply), logging:Highlight(old), logging:Highlight(new)))
		end)
	end)

	addModule("Karma losses", function(module)
		module:Hook("BaseWars_KarmaChanged", "basewars_blogs_karma", function(ply, old, new)
			if not IsValid(ply) or new >= old then return end
			module:Log(string.format(BaseWars.LANG.BLogsKarmaLoss,
				playerToken(ply), logging:Highlight(old - new), logging:Highlight(new)))
		end)
	end)

	BaseWars.BLogsRegistered = logging
end

hook.Add("bLogs_FullyLoaded", "BaseWars.bLogs.Register", register)
register()
