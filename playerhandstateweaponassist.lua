--[[
	PlayerHandStateWeaponAssist

	Fix the off hand lagging behind the weapon while using a foregrip (the
	historical VRPlus "weapon_assist" fix from 9dc0cba, restored for the
	Update 247 / Diesel 3.0 regression).

	Vanilla anchors the assist hand to the weapon unit's transform, which the
	engine has not necessarily applied to the rendered weapon yet, so the
	assist hand trails behind while the player moves. The dominant hand's
	PlayerHandStateWeapon fix keeps the fresh controller-derived weapon
	transform in __weapon_position/__weapon_rotation; anchor to that instead
	so both hands and the weapon agree on where they are each frame.
--]]

function PlayerHandStateWeaponAssist:update(t, dt)
	local weapon_state = self:hsm():other_hand():current_state()
	local weapon_unit = weapon_state and weapon_state._weapon_unit

	if weapon_unit and alive(weapon_unit) and self._assist_position then
		local pos

		if weapon_state.__weapon_position and weapon_state.__weapon_rotation then
			-- Fresh transform written by the dominant-hand weapon fix this frame
			pos = weapon_state.__weapon_position + self._assist_position:rotate_with(weapon_state.__weapon_rotation)
		else
			-- Fall back to the vanilla computation if the cache is not there yet
			pos = weapon_state:hsm():position() + self._assist_position:rotate_with(weapon_unit:rotation())
		end

		self._hand_unit:set_position(pos)
	end
end