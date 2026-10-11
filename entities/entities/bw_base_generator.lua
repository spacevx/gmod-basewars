AddCSLuaFile()

ENT.Base = "bw_base"
ENT.Type = "anim"
ENT.PrintName = "Base Generator"

ENT.Model = "models/props_wasteland/laundry_washer003.mdl"
ENT.Skin = 0

ENT.IsGenerator = true

ENT.PowerGenerated = 15
ENT.PowerCapacity = 1000
ENT.TransmitRadius = 600
ENT.TransmitRate = 20
ENT.ThinkPeriods = 3

do
	local m_min = math.min
	function ENT:TransmitPower(tbl, count, periods)
		local rate = self.TransmitRate * (periods or 1)
		local power = self:GetPower()
		local start = power
		for i = 1, count do
			if power <= 0 then break end
			local v = tbl[i]
			if not IsValid(v) then continue end
			local Pow = v.GetPower and v:GetPower() or 0
			local Max = v.GetMaxPower and v:GetMaxPower() or 0
			if Max < 1 then continue end
			if Pow >= Max then continue end
			local Transmit = m_min(rate, power)
			Transmit = m_min(Transmit, (Max - Pow))
			v:ReceivePower(Transmit)
			power = power - Transmit
		end
		if power ~= start then self:SetPower(power) end
	end
end

if SERVER then
	local powered_ents = {}
	local powered_ent_count = 0
	local function realAdd(ent)
		if not (IsValid(ent) and ent.IsElectronic) then return end
		powered_ent_count = powered_ent_count + 1
		powered_ents[powered_ent_count] = ent
		ent.__powerIndex = powered_ent_count
	end
	hook.Add("OnEntityCreated", "power_system_workaround", function(ent)
		timer.Simple(0, function() realAdd(ent) end)
	end)
	hook.Add("EntityRemoved", "power_system_workaround", function(ent)
		if not ent.__powerIndex then return end
		local new = {}
		local count = 0
		for _, v in ipairs(powered_ents) do
			if IsValid(v) and v ~= ent then
				count = count + 1
				new[count] = v
				v.__powerIndex = count
			end
		end
		powered_ents = new
		powered_ent_count = count
	end)
	hook.Add("OnReloaded", "power_system_workaround", function()
		local new = {}
		local count = 0
		for _, v in ipairs(ents.GetAll()) do
			if v.IsElectronic then
				count = count + 1
				new[count] = v
				v.__powerIndex = count
			end
		end
		powered_ents = new
		powered_ent_count = count
	end)
	function ENT:Think()
		local periods = self.ThinkPeriods
		if not self:BadlyDamaged() then
			self:ReceivePower(self.PowerGenerated * periods)
		end
		do
			local time = CurTime()
			if not (self.nextNearbyCache and self.nearbyEnts) or self.nextNearbyCache <= time then
				local res = {}
				local count = 0
				self.TransmitRadiusSqr = self.TransmitRadiusSqr or (self.TransmitRadius*self.TransmitRadius)
				local dist_sqr = self.TransmitRadiusSqr
				local self_pos = self:GetPos()
				for i = 1, powered_ent_count do
					local v = powered_ents[i]
					if v ~= self and self_pos:DistToSqr(v:GetPos()) <= dist_sqr then
						count = count + 1
						res[count] = v
					end
				end
				self.nearbyEnts = res
				self.nearbyCount = count
				self.nextNearbyCache = time + 2
			end
			self:TransmitPower(self.nearbyEnts, self.nearbyCount, periods)
		end
		if self:BadlyDamaged() and math.random(0, 11) < periods then
			self:Spark()
		end
		self:WaterThink(periods)
		if self:BadlyDamaged() then return self:ScheduleThink() end
		self:ThinkFunc()
		return self:ScheduleThink()
	end
end
