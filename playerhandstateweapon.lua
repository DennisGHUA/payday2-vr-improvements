--[[
	PlayerHandStateWeapon

	If view rotation is enabled, move gadget and firemode selectors
--]]

local old_update = PlayerHandStateWeapon.update
function PlayerHandStateWeapon:update(t, dt)
	old_update(self, t, dt)

	-- If turning is disabled, don't affect the mappings.
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

	local touch_limit = 0.3

	local controller = managers.vr:hand_state_machine():controller()
	local axis = controller:get_input_axis("touchpad_primary")

	if axis.y < -touch_limit then
		managers.hud:show_controller_assist("hud_vr_controller_gadget")
	elseif touch_limit < axis.y then
		managers.hud:show_controller_assist("hud_vr_controller_firemode")
	elseif axis.x < -touch_limit and self._can_switch_weapon_hand then
		managers.hud:show_controller_assist("hud_vr_controller_weapon_hand_switch")
	else
		managers.hud:hide_controller_assist()
	end
end
