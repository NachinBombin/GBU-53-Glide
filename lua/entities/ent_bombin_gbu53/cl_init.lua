include("shared.lua")
include("cl_trailsystem.lua")

-- ============================================================
-- CLIENT ENGINE SOUND
-- CreateSound here (client-side) so the positional 3-D sound
-- actually works.  A server-side CreateSound on a custom wav
-- is never heard because the client never precaches it.
-- ============================================================

local ENGINE_LOOP_SOUND = "ambient/wind/wind_atlas_loop1.wav"

-- ============================================================
-- DAMAGE TIER PARTICLES
-- ============================================================

local TIER_PARTICLES = {
	[1] = { name = "fire_medium_01",  offset = Vector(0, -30,  5), scale = 0.6 },
	[2] = { name = "fire_large_01",   offset = Vector(0, -30, 10), scale = 1.0 },
	[3] = { name = "fire_large_02",   offset = Vector(0, -20, 15), scale = 1.4 },
}

net.Receive("bombin_gbu53_damage_tier", function()
	local entIdx = net.ReadUInt(16)
	local tier   = net.ReadUInt(2)

	local ent = Entity(entIdx)
	if not IsValid(ent) then return end

	-- Stop any running particle before starting the next tier
	local prev = ent.GBU53_ActiveParticle
	if IsValid(prev) then prev:StopEmission() end

	if tier == 0 then
		ent.GBU53_ActiveParticle = nil
		return
	end

	local cfg = TIER_PARTICLES[tier]
	if not cfg then return end

	local ps = CreateParticleSystem(ent, cfg.name, PATTACH_POINT_FOLLOW, 0)
	if IsValid(ps) then
		ps:SetControlPoint(0, ent:GetPos() + cfg.offset)
		ps:SetSortOrigin(ent:GetPos())
		ent.GBU53_ActiveParticle = ps
	end
end)

-- ============================================================
-- ENTITY HOOKS
-- ============================================================

function ENT:Initialize()
	-- Register trail
	GBU53Trail_Register(self)

	-- Client-side engine sound
	self.GBU53_EngineSound = CreateSound(self, ENGINE_LOOP_SOUND)
	if self.GBU53_EngineSound then
		self.GBU53_EngineSound:SetSoundLevel(78)
		self.GBU53_EngineSound:ChangePitch(95, 0)
		self.GBU53_EngineSound:ChangeVolume(0.85, 0)
		self.GBU53_EngineSound:Play()
	end
end

function ENT:Think()
	-- Keep sound alive and positioned while the entity exists
	if self.GBU53_EngineSound and not self.GBU53_EngineSound:IsPlaying() then
		self.GBU53_EngineSound:Play()
	end
end

function ENT:OnRemove()
	GBU53Trail_Unregister(self)

	if self.GBU53_EngineSound then
		self.GBU53_EngineSound:FadeOut(0.4)
		self.GBU53_EngineSound = nil
	end

	if IsValid(self.GBU53_ActiveParticle) then
		self.GBU53_ActiveParticle:StopEmission()
		self.GBU53_ActiveParticle = nil
	end
end

function ENT:Draw()
	self:DrawModel()
end
