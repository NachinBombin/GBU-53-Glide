include("shared.lua")

-- ================================================================
-- GBU-53/B StormBreaker -- CLIENT
-- Health degradation FX: flames, sparks via particle system.
-- gbu53.mdl is a compact glide bomb (~30u body).
-- ================================================================

game.AddParticles("particles/fire_01.pcf")
PrecacheParticleSystem("fire_medium_02")

-- Damage tier particle offsets tuned for the GBU-53 compact body
local TIER_OFFSETS = {
	[1] = {
		{ x =  12, y =   0, z = 0 },   -- starboard body
		{ x = -12, y =   0, z = 0 },   -- port body
	},
	[2] = {
		{ x =  12, y =   0, z = 0 },
		{ x = -12, y =   0, z = 0 },
		{ x =   0, y =  -8, z = 2 },   -- tail section
		{ x =   0, y =  12, z = 2 },   -- nose section
	},
}

local TIER_BURST_DELAY = { [1] = 5.0, [2] = 2.5, [3] = 0.9 }
local TIER_BURST_COUNT = { [1] = 1,   [2] = 2,   [3] = 5   }

local GBU53States = {}

local function BurstAt(pos, tier)
	local ed = EffectData()
	ed:SetOrigin(pos)
	ed:SetScale(1)
	util.Effect("Explosion", ed)

	local sed = EffectData()
	sed:SetOrigin(pos)
	sed:SetScale(1)
	util.Effect("ManhackSparks", sed)

	if tier >= 2 then
		local eed = EffectData()
		eed:SetOrigin(pos)
		eed:SetScale(1)
		util.Effect("ElectricSpark", eed)
	end
end

local function SpawnBurstFX(ent, tier)
	if not IsValid(ent) then return end
	local count = TIER_BURST_COUNT[tier] or 1
	local right = ent:GetRight()
	for i = 1, count do
		local offset = right * math.Rand(-12, 12)
		BurstAt(ent:GetPos() + offset, tier)
	end
end

local function ApplyFlameParticles(state, ent, tier)
	for _, p in ipairs(state.particles) do
		if IsValid(p) then p:StopEmission() end
	end
	state.particles = {}

	local offsets = TIER_OFFSETS[tier]
	if not offsets then return end

	for _, off in ipairs(offsets) do
		local p = CreateParticleSystem(ent, "fire_medium_02", PATTACH_ABSORIGIN_FOLLOW)
		if IsValid(p) then
			p:SetControlPoint(0, ent:GetPos() + ent:GetRight()   * off.x
			                                 + ent:GetUp()      * off.z
			                                 + ent:GetForward() * off.y)
			table.insert(state.particles, p)
		end
	end
end

net.Receive("bombin_gbu53_damage_tier", function()
	local idx  = net.ReadUInt(16)
	local tier = net.ReadUInt(2)

	local ent = ents.GetByIndex(idx)

	if not IsValid(ent) then
		GBU53States[idx] = GBU53States[idx] or { tier = 0, particles = {}, nextBurst = 0, pendingTier = nil }
		GBU53States[idx].pendingTier = tier
		return
	end

	local state = GBU53States[idx] or { tier = 0, particles = {}, nextBurst = 0, pendingTier = nil }
	GBU53States[idx] = state
	state.tier = tier

	ApplyFlameParticles(state, ent, tier)
end)

hook.Add("Think", "bombin_gbu53_fx_think", function()
	local ct = CurTime()
	for idx, state in pairs(GBU53States) do
		local ent = ents.GetByIndex(idx)
		if not IsValid(ent) then
			for _, p in ipairs(state.particles) do
				if IsValid(p) then p:StopEmission() end
			end
			GBU53States[idx] = nil
			continue
		end

		-- Resolve pending tier set before ent was valid
		if state.pendingTier then
			ApplyFlameParticles(state, ent, state.pendingTier)
			state.tier        = state.pendingTier
			state.pendingTier = nil
		end

		if state.tier > 0 and ct >= state.nextBurst then
			local delay = TIER_BURST_DELAY[state.tier] or 5.0
			state.nextBurst = ct + delay * math.Rand(0.7, 1.3)
			SpawnBurstFX(ent, state.tier)
		end

		-- Keep particle control points tracking the entity
		local offsets = TIER_OFFSETS[state.tier]
		if offsets then
			for i, p in ipairs(state.particles) do
				if IsValid(p) and offsets[i] then
					local off = offsets[i]
					p:SetControlPoint(0, ent:GetPos() + ent:GetRight()   * off.x
					                                 + ent:GetUp()      * off.z
					                                 + ent:GetForward() * off.y)
				end
			end
		end
	end
end)

function ENT:Initialize()
	self:SetModelScale(1.0, 0)
	self:SetBodygroup(1, 1)
end

function ENT:OnRemove()
	local state = GBU53States[self:EntIndex()]
	if not state then return end
	for _, p in ipairs(state.particles) do
		if IsValid(p) then p:StopEmission() end
	end
	GBU53States[self:EntIndex()] = nil
end
