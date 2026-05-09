-- ============================================================
-- GBU-53 TRAIL SYSTEM  (ported from ent_bombin_shahed)
-- Three beam contrails: centre-rear + two fin-tips.
-- Runs entirely client-side; no net messages needed.
-- ============================================================

local TRAIL_LIFETIME  = 6       -- seconds each sample lives
local SAMPLE_RATE     = 0.025   -- seconds between position samples (40 Hz)
local TRAIL_WIDTH_CTR = 6       -- beam width, centre trail
local TRAIL_WIDTH_TIP = 3       -- beam width, fin-tip trails
local TRAIL_ALPHA     = 180     -- max alpha
local TRAIL_TEX       = "trails/smoke"

-- Offsets in local model space (GBU-53 body is narrow)
-- [1] = centre exhaust rear
-- [2] = starboard fin-tip
-- [3] = port fin-tip
local TRAIL_OFFSETS = {
	Vector(  0,  -55,   0 ),
	Vector( 28,  -10,  -4 ),
	Vector(-28,  -10,  -4 ),
}

local GBU53Trails = {}   -- [EntIndex] = { { samples }, { samples }, { samples } }

-- ============================================================
-- SAMPLE COLLECTOR
-- ============================================================

hook.Add("Think", "bombin_gbu53_trail_sample", function()
	local now = CurTime()

	for entIdx, trailData in pairs(GBU53Trails) do
		local ent = Entity(entIdx)
		if not IsValid(ent) then
			GBU53Trails[entIdx] = nil
			continue
		end

		if (trailData.nextSample or 0) > now then continue end
		trailData.nextSample = now + SAMPLE_RATE

		local pos = ent:GetPos()
		local ang = ent:GetAngles()

		for i = 1, 3 do
			local worldOffset = LocalToWorld(TRAIL_OFFSETS[i], Angle(0,0,0), pos, ang)
			table.insert(trailData[i], { pos = worldOffset, t = now })
		end
	end
end)

-- ============================================================
-- RENDERER
-- ============================================================

hook.Add("PostDrawTranslucentRenderables", "bombin_gbu53_trail_draw", function()
	local now = CurTime()

	for entIdx, trailData in pairs(GBU53Trails) do
		local ent = Entity(entIdx)
		if not IsValid(ent) then continue end

		for i = 1, 3 do
			local samples = trailData[i]

			-- Purge expired samples from the front
			while samples[1] and (now - samples[1].t) > TRAIL_LIFETIME do
				table.remove(samples, 1)
			end

			if #samples < 2 then continue end

			local width = (i == 1) and TRAIL_WIDTH_CTR or TRAIL_WIDTH_TIP

			render.SetMaterial(Material(TRAIL_TEX))
			render.StartBeam(#samples)

			for j, s in ipairs(samples) do
				local age   = now - s.t
				local frac  = 1 - (age / TRAIL_LIFETIME)   -- 1 = fresh, 0 = old
				local alpha = frac * frac * TRAIL_ALPHA     -- quadratic fade

				render.AddBeam(
					s.pos,
					width * frac,
					j / #samples,
					ColorAlpha(color_white, alpha)
				)
			end

			render.EndBeam()
		end
	end
end)

-- ============================================================
-- REGISTRATION  (called from cl_init.lua)
-- ============================================================

function GBU53Trail_Register(ent)
	if not IsValid(ent) then return end
	local idx = ent:EntIndex()
	if GBU53Trails[idx] then return end  -- already registered
	GBU53Trails[idx] = {
		[1] = {},
		[2] = {},
		[3] = {},
		nextSample = CurTime(),
	}
end

function GBU53Trail_Unregister(ent)
	if not IsValid(ent) then return end
	GBU53Trails[ent:EntIndex()] = nil
end
