local commands = {
	{
		Name = "addmoney", Method = "GiveMoney", Min = 0, Max = 10^12, Hint = "Money",
		Help = "Give players money.", Message = "{A} gave {V} to {T}.", Currency = true,
	},
	{
		Name = "takemoney", Method = "TakeMoney", Min = 0, Max = 10^12, Hint = "Money",
		Help = "Take money from players.", Message = "{A} took {V} from {T}.", Currency = true,
	},
	{
		Name = "setmoney", Method = "SetMoney", Min = 0, Max = 10^12, Hint = "Money",
		Help = "Set players' money.", Message = "{A} set {T}'s money to {V}.", Currency = true,
	},
	{
		Name = "addlevel", Method = "AddLevel", Min = 0, Max = BaseWars.Config.LevelSettings.MaxLevel, Hint = "Level",
		Help = "Add levels to players.", Message = "{A} added {V} levels to {T}.",
	},
	{
		Name = "setlevel", Method = "SetLevel", Min = 0, Max = BaseWars.Config.LevelSettings.MaxLevel, Hint = "Level",
		Help = "Set players' level.", Message = "{A} set {T}'s level to {V}.",
	},
	{
		Name = "addxp", Method = "AddXP", Min = 0, Max = 1250250, Hint = "XP",
		Help = "Give players XP.", Message = "{A} added {V} XP to {T}.",
	},
	{
		Name = "setxp", Method = "SetXP", Min = 0, Max = 1250250, Hint = "XP",
		Help = "Set players' XP.", Message = "{A} set {T}'s XP to {V}.",
	},
	{
		Name = "addkarma", Method = "AddKarma", Min = -100, Max = 100, Hint = "Karma",
		Help = "Add karma to players.", Message = "{A} added {V} karma to {T}.",
	},
	{
		Name = "setkarma", Method = "SetKarma", Min = -100, Max = 100, Hint = "Karma",
		Help = "Set players' karma.", Message = "{A} set {T}'s karma to {V}.",
	},
}

local function registerCommand(spec)
	sam.command.new(spec.Name)
		:SetCategory("BaseWars")
		:SetPermission("basewars." .. spec.Name, "admin")
		:AddArg("player")
		:AddArg("number", {min = spec.Min, max = spec.Max, hint = spec.Hint, round = true})
		:Help(spec.Help)
		:OnExecute(function(caller, targets, amount)
			for _, target in ipairs(targets) do
				target[spec.Method](target, amount)
			end
			local value = spec.Currency and string.format(BaseWars.LANG.CURFORMER, BaseWars.NumberFormat(amount)) or amount
			sam.player.send_message(nil, spec.Message, {A = caller, T = targets, V = value})
		end)
	:End()
end

for _, spec in ipairs(commands) do
	registerCommand(spec)
end
