
local function add_locomotion_inputs(self, hand, key_map)
	if not VRPlusMod._data.movement_locomotion then
		return
	end

	local hand_name = hand == 1 and "r" or "l"

	-- Prevent moving forwards from jumping for Rift users
	key_map["d_up_" .. hand_name] = nil
end

Hooks:PostHook(EmptyHandState, "apply", "VRPlusInterationButton", function(self, hand, key_map)
	local hand_name = hand == 1 and "r" or "l"
	local nice_name = hand == 1 and "right" or "left"

	if VRPlusMod._data.comfort.interact_mode ~= VRPlusMod.C.INTERACT_GRIP then
		-- TODO should we just override it completely?
		table.insert(key_map["trigger_" .. hand_name], "interact_" .. nice_name)
	end

	if VRPlusMod._data.comfort.interact_mode == VRPlusMod.C.INTERACT_TRIGGER then
		key_map["grip_" .. hand_name][1] = nil
	end

	add_locomotion_inputs(self, hand, key_map)
end)

Hooks:PostHook(MaskHandState, "apply", "VRPlusCasingRotation", function(self, hand, key_map)
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

	local hand_name = hand == 1 and "r" or "l"

	key_map["dpad_" .. hand_name] = { "touchpad_primary" }
end)

Hooks:PostHook(PointHandState, "apply", "VRPlusPointHandSprint", add_locomotion_inputs)
