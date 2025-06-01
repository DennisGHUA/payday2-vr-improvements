
local old_update = HandMelee.update
function HandMelee:update(unit, t, dt)
	local mode = VRPlusMod and VRPlusMod._data and VRPlusMod._data.tweaks and VRPlusMod._data.tweaks.weapon_melee

	-- Apply rotation if the turning mode is enabled
	if VRPlusMod and VRPlusMod._data and VRPlusMod._data.turning_mode and VRPlusMod._data.turning_mode ~= VRPlusMod.C.TURNING_OFF then
		-- Wrap everything in pcall for safety
		pcall(function()
			-- Get the player's state to access rotation logic
			local player_unit = managers.player and managers.player:player_unit()
			if player_unit and alive(player_unit) then
				local player_state = player_unit:movement() and player_unit:movement():current_state()
				
				-- Try to call the do_melee_rotation method directly
				if player_state and player_state.do_melee_rotation then
					player_state:do_melee_rotation(t, dt)
				-- If that's not available, use the exposed rotation function
				elseif _G.PlayerStandardVR and PlayerStandardVR._rotation_exposed and PlayerStandardVR._do_rotation_function and player_state then
					PlayerStandardVR._do_rotation_function(player_state, t, dt)
				end
			end
		end)
	end
	
	-- Add MeleeHandState functionality directly here for safety
	if _G.MeleeHandState then
		pcall(function()
			-- Apply the MeleeHandState hook functionality directly
			local controller = managers.controller:get_vr_controller()
			if controller and VRPlusMod and VRPlusMod._data and VRPlusMod._data.turning_mode and VRPlusMod._data.turning_mode ~= VRPlusMod.C.TURNING_OFF then
				-- In the original code, this would be done via hooking MeleeHandState:apply
				-- But we'll do it here to avoid issues with the hook
						-- This would map dpad inputs to touchpad_primary in MeleeHandState
				-- Since we can't do that directly, we'll check for dpad inputs and simulate touchpad_primary
				local requires_press = VRPlusMod._data.rotation_requires_press
				local dpad_l_pressed = controller:get_input_bool("d_left_l") or controller:get_input_bool("d_right_l")
				local dpad_r_pressed = controller:get_input_bool("d_left_r") or controller:get_input_bool("d_right_r")
				
				-- Also check the generic trackpad buttons for HTC Vive support
				if requires_press then
					dpad_l_pressed = dpad_l_pressed or controller:get_input_bool("trackpad_button_l")
					dpad_r_pressed = dpad_r_pressed or controller:get_input_bool("trackpad_button_r")
				end
				
				if dpad_l_pressed or dpad_r_pressed then
					-- Get the axis input from the dpad
					local x_axis = 0
					if controller:get_input_bool("d_left_l") or controller:get_input_bool("d_left_r") then
						x_axis = -1
					elseif controller:get_input_bool("d_right_l") or controller:get_input_bool("d_right_r") then
						x_axis = 1
					end
					
					-- This creates a virtual touchpad_primary axis input
					controller._virtual_touchpad_primary = {x = x_axis, y = 0}
				end
			end
		end)
	end

	if mode ~= VRPlusMod.C.WEAPON_MELEE_ENABLED and self:has_weapon() then
		if mode ~= VRPlusMod.C.WEAPON_MELEE_LOUD or managers.groupai:state():whisper_mode() then
			return
		end
	end

	return old_update(self, unit, t, dt)
end
