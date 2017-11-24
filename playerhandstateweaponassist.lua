--[[
	PlayerHandStateWeaponAssist

	Fix the off hand lagging behind the weapon while using a foregrip
--]]

-- Move the update position logic over to post update
function PlayerHandStateWeaponAssist:update() end

-- Lines: 30 to 38
function PlayerHandStateWeaponAssist:post_update(t, dt)
	local state = self:hsm():other_hand():current_state()
	local weapon_unit = state._weapon_unit

	if alive(weapon_unit) and self._assist_position then
		self._hand_unit:set_position(state.__weapon_position + self._assist_position:rotate_with(state.__weapon_rotation))
	end
end
