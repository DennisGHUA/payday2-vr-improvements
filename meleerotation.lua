--[[
	MeleeRotation
	
	Ensures that rotation works when the player is using a melee weapon
]]

-- Add a hook to the melee state to enable rotation
Hooks:PostHook(MeleeHandState, "apply", "VRPlusMeleeRotation", function(self, hand, key_map)
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

	local hand_name = hand == 1 and "r" or "l"

	-- Enable rotation during melee by mapping the dpad input to touchpad_primary
	key_map["dpad_" .. hand_name] = { "touchpad_primary" }
end)
