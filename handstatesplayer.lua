
Hooks:PostHook(EmptyHandState, "apply", "VRPlusInterationButton", function(self, hand, key_map)
	local hand_name = hand == 1 and "r" or "l"
	local nice_name = hand == 1 and "right" or "left"

	if VRPlusMod._data.comfort.interact_mode ~= VRPlusMod.C.INTERACT_GRIP then
		key_map["trigger_" .. hand_name] = "interact_" .. nice_name
	end

	if VRPlusMod._data.comfort.interact_mode == VRPlusMod.C.INTERACT_TRIGGER then
		key_map["grip_" .. hand_name] = nil
	end
end)
