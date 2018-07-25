
local function add_offhand_actions(hand_name, key_map)
	if VRPlusMod._data.comfort.crouching ~= VRPlusMod.C.CROUCH_NONE then
		key_map["menu_" .. hand_name] = { "duck" }
	end

	if VRPlusMod._data.movement_locomotion then
		-- Shouldn't break warp, as dpad_ isn't used outside the weapon hand anymore
		-- Still do it here, just to be safe
		key_map["dpad_" .. hand_name] = { "move" }

		-- Don't use 'warp' for running/jumping, as it seems somehow tied
		-- to the Rift's 'Y' button.
		key_map["trackpad_button_" .. hand_name] = { "jump" }
	end
end

-- Note EmptyHandState deals with everything for your non-weapon hand.
-- including shouting down civs, bagging loot, etc.
Hooks:PostHook(EmptyHandState, "apply", "VRPlusOffHandActions", function(self, hand, key_map)
	if self.vrplus_config_marker then return end

	local hand_name = hand == 1 and "r" or "l"
	local nice_name = hand == 1 and "right" or "left"

	if VRPlusMod._data.comfort.interact_mode ~= VRPlusMod.C.INTERACT_GRIP then
		-- TODO should we just override it completely?
		local key = "trigger_" .. hand_name

		if not key_map[key] then
			key_map[key] = {}
		end

		table.insert(key_map[key], "interact_" .. nice_name)
	end

	if VRPlusMod._data.comfort.interact_mode == VRPlusMod.C.INTERACT_TRIGGER then
		key_map["grip_" .. hand_name][1] = nil
	end

	if VRPlusMod._data.movement_locomotion then
		-- Prevent moving forwards from jumping for Rift users
		key_map["d_up_" .. hand_name] = nil
	end

	add_offhand_actions(hand_name, key_map)
end)

Hooks:PostHook(PointHandState, "apply", "VRPlusPointingHandActions", function(self, hand, key_map)
	if self.vrplus_config_marker then return end

	local hand_name = hand == 1 and "r" or "l"

	if VRPlusMod._data.movement_locomotion then
		-- Prevent moving forwards from jumping for Rift users
		key_map["d_up_" .. hand_name] = nil
	end

	add_offhand_actions(hand_name, key_map)
end)

Hooks:PostHook(MaskHandState, "apply", "VRPlusCasingRotation", function(self, hand, key_map)
	if self.vrplus_config_marker then return end

	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

	local hand_name = hand == 1 and "r" or "l"

	key_map["dpad_" .. hand_name] = { "touchpad_primary" }
end)

Hooks:PostHook(BeltHandState, "apply", "VRPlusBeltActions", function(self, hand, key_map)
	if self.vrplus_config_marker then return end

	local weapon_hand = managers.vr:get_setting("default_weapon_hand"):sub(1,1)
	local hand_name = hand == 1 and "r" or "l"

	if VRPlusMod._data.turning_mode ~= VRPlusMod.C.TURNING_OFF and hand_name == weapon_hand then
		key_map["dpad_" .. hand_name] = { "touchpad_primary" }
	end

	if hand_name ~= weapon_hand then
		add_offhand_actions(hand_name, key_map)
	end
end)

Hooks:PostHook(WeaponHandState, "apply", "VRPlusMoveGadgetFiremode", function(self, hand, key_map)
	if self.vrplus_config_marker then return end

	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then
		return
	end

	-- By default
	-- switch_hands -> up
	-- weapon_firemode -> left
	-- weapon_gadget ->  right

	local hand_name = hand == 1 and "r" or "l"
	key_map["d_left_" .. hand_name] = nil
	key_map["d_right_" .. hand_name] = nil
	key_map["d_up_" .. hand_name] = { "weapon_gadget" }
	key_map["d_down_" .. hand_name] = { "weapon_firemode" }
end)
