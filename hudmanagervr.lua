--[[
	HUDManagerVR

	Set a speedup effect when the heist ends
]]

Hooks:PostHook(HUDManager, "setup_endscreen_hud", "VRPlusSpeedUpEndscreen", function(self)
	self._hud_stage_endscreen:set_speed_up(VRPlusMod._data.tweaks.endscreen_speedup)
end)
