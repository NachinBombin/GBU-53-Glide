if not SERVER then return end

CreateConVar("npc_bombingbu53_lifetime",     "40",   FCVAR_ARCHIVE, "GBU-53 loiter lifetime (seconds)")
CreateConVar("npc_bombingbu53_speed",        "250",  FCVAR_ARCHIVE, "GBU-53 orbit speed (u/s)")
CreateConVar("npc_bombingbu53_radius",       "2500", FCVAR_ARCHIVE, "GBU-53 orbit radius (units)")
CreateConVar("npc_bombingbu53_height",       "2500", FCVAR_ARCHIVE, "GBU-53 altitude above ground (units)")
CreateConVar("npc_bombingbu53_dive_damage",  "700",  FCVAR_ARCHIVE, "GBU-53 explosion damage")
CreateConVar("npc_bombingbu53_dive_radius",  "900",  FCVAR_ARCHIVE, "GBU-53 explosion radius (units)")

util.AddNetworkString("BombinGBU53_ManualSpawn")

net.Receive("BombinGBU53_ManualSpawn", function(len, ply)
	if not IsValid(ply) then return end

	local tr = util.TraceLine({
		start  = ply:EyePos(),
		endpos = ply:EyePos() + ply:EyeAngles():Forward() * 3000,
		filter = ply,
	})

	local centerPos = tr.Hit and tr.HitPos or (ply:GetPos() + Vector(0, 0, 100))
	local callDir   = ply:EyeAngles():Forward()
	callDir.z = 0
	if callDir:LengthSqr() <= 1 then callDir = Vector(1, 0, 0) end
	callDir:Normalize()

	if not scripted_ents.GetStored("ent_bombin_gbu53") then
		ply:PrintMessage(HUD_PRINTCENTER, "[Bombin GBU-53] Entity not registered!")
		return
	end

	local ent = ents.Create("ent_bombin_gbu53")
	if not IsValid(ent) then
		ply:PrintMessage(HUD_PRINTCENTER, "[Bombin GBU-53] Spawn failed!")
		return
	end

	ent:SetPos(centerPos)
	ent:SetAngles(callDir:Angle())
	ent:SetVar("CenterPos",           centerPos)
	ent:SetVar("CallDir",             callDir)
	ent:SetVar("Lifetime",            GetConVar("npc_bombingbu53_lifetime"):GetFloat())
	ent:SetVar("Speed",               GetConVar("npc_bombingbu53_speed"):GetFloat())
	ent:SetVar("OrbitRadius",         GetConVar("npc_bombingbu53_radius"):GetFloat())
	ent:SetVar("SkyHeightAdd",        GetConVar("npc_bombingbu53_height"):GetFloat())
	ent:SetVar("DIVE_ExplosionDamage", GetConVar("npc_bombingbu53_dive_damage"):GetFloat())
	ent:SetVar("DIVE_ExplosionRadius", GetConVar("npc_bombingbu53_dive_radius"):GetFloat())
	ent:Spawn()
	ent:Activate()

	ply:PrintMessage(HUD_PRINTCENTER, "[Bombin GBU-53] GBU-53/B StormBreaker inbound!")
end)
