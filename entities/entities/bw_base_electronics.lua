AddCSLuaFile()

ENT.Base = "bw_base"
ENT.Type = "anim"
ENT.PrintName = "Base Electricals"

ENT.Model = "models/props_c17/metalPot002a.mdl"
ENT.Skin = 0

ENT.IsElectronic = true
ENT.PowerRequired = 5
ENT.PowerCapacity = 1000
ENT.ThinkPeriods = 3

function ENT:DrainPower(val)
	if not self:IsPowered(val) then return false end
	self:SetPower(self:GetPower() - (val or self.PowerRequired))
	return true
end

function ENT:IsPowered(val)
	return self:GetPower() >= (val or self.PowerRequired)
end

if SERVER then
	function ENT:ConsumePower(periods)
		local required = self.PowerRequired
		if required <= 0 then return true end
		local steps = math.min(periods, math.floor(self:GetPower() / required))
		if steps < 1 then return false end
		return self:DrainPower(steps * required)
	end

	function ENT:Think()
		self:ThinkFuncBypass()
		local periods = self.ThinkPeriods
		if self:IsPowered() and self:BadlyDamaged() and math.random(0, 11) < periods then
			self:Spark()
		end
		self:WaterThink(periods)
		if not self:ConsumePower(periods) or self:BadlyDamaged() then
			if self:GetUsable() then self:SetUsable(false) end
			return self:ScheduleThink()
		end
		local Res = self:CheckUsable()
		local State = Res ~= false
		if State ~= self:GetUsable() then
			self:SetUsable(State)
		end
		self:ThinkFunc()
		return self:ScheduleThink()
	end
	function ENT:CheckUsable()
	end
	function ENT:Use(activator, caller, usetype, value)
		self:UseFuncBypass(activator, caller, usetype, value)
		if not self:GetUsable() then return end
		if self:CheckUsable() == false then return end
		if not self:IsPowered() or self:BadlyDamaged() then
			self:EmitSound("buttons/button10.wav")
		return end
		self:UseFunc(activator, caller, usetype, value)
	end
end
