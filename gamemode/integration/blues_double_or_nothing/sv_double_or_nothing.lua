if not file.Exists("bdon_config.lua", "LUA") then return end

local PLAYER = FindMetaTable("Player")

if not PLAYER.canAfford then
	function PLAYER:canAfford(amount)
		return isnumber(amount) and amount == amount and amount >= 0 and amount < math.huge
			and self:GetMoney() >= amount
	end
end

if not PLAYER.addMoney then
	function PLAYER:addMoney(amount)
		if not isnumber(amount) or amount ~= amount or amount == math.huge or amount == -math.huge then return end
		if amount > 0 then
			self:GiveMoney(amount)
		elseif amount < 0 then
			self:TakeMoney(-amount)
		end
	end
end
