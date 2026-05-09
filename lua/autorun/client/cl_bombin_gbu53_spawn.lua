if not CLIENT then return end

-- Quick spawn bind: type "bombin_gbu53_spawn" in console to call one in.
concommand.Add("bombin_gbu53_spawn", function()
	net.Start("BombinGBU53_ManualSpawn")
	net.SendToServer()
end)
