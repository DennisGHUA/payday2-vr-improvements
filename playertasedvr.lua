--[[
	PlayerTasedVR

	Prevent crashes when tased - See #37
--]]

Hooks:PostHook(PlayerTasedVR, "init", "VRPlusFixTaserCrash", function(self)
	self._shooting_weapons = {}
end)
