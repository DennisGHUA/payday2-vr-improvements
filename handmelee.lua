
local old_update = HandMelee.update
function HandMelee:update(unit, t, dt)
	local mode = VRPlusMod._data.tweaks.weapon_melee

	-- Apply rotation if the turning mode is enabled
	if VRPlusMod._data.turning_mode ~= VRPlusMod.C.TURNING_OFF then
		-- Get the player's state to access rotation logic
		local player_unit = managers.player and managers.player:player_unit()
		if player_unit and alive(player_unit) then
			local player_state = player_unit:movement():current_state()
			
			-- Try to call the do_melee_rotation method directly
			if player_state and player_state.do_melee_rotation then
				player_state:do_melee_rotation(t, dt)
			-- If that's not available, use the exposed rotation function
			elseif PlayerStandardVR._rotation_exposed and PlayerStandardVR._do_rotation_function and player_state then
				PlayerStandardVR._do_rotation_function(player_state, t, dt)
			end
		end
	end

	if mode ~= VRPlusMod.C.WEAPON_MELEE_ENABLED and self:has_weapon() then
		if mode ~= VRPlusMod.C.WEAPON_MELEE_LOUD or managers.groupai:state():whisper_mode() then
			return
		end
	end

	return old_update(self, unit, t, dt)
end
