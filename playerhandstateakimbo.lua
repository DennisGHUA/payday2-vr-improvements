-- Copypasted function from regular game
-- Changed to fix a crash
-- If nothing else, this will give clearer crash logs
function PlayerHandStateAkimbo:at_enter(prev_state)
	PlayerHandStateAkimbo.super.at_enter(self, prev_state)

	-- Added extra "if managers.player" check
	if managers.player and alive(managers.player:player_unit()) then
		local equipped_weapon = managers.player:player_unit():inventory():equipped_unit()

		if alive(equipped_weapon) and equipped_weapon:base().akimbo then
			self:_link_weapon(equipped_weapon:base()._second_gun)
		else
			self:hsm():set_default_state("idle")

			return
		end
	end

	self._hand_unit:melee():set_weapon_unit(self._weapon_unit)
	self:hsm():enter_controller_state("empty")
	self:hsm():enter_controller_state("akimbo")

	local sequence = self._sequence
	local tweak = tweak_data.vr:get_offset_by_id(self._weapon_unit:base().name_id)

	if tweak.grip then
		sequence = tweak.grip
	end

	if self._hand_unit and sequence and self._hand_unit:damage():has_sequence(sequence) then
		self._hand_unit:damage():run_sequence_simple(sequence)
	end
end

-- Fixes a vanilla bug causing the hand tracking to have a big delay
Hooks:PostHook(PlayerHandStateAkimbo, "update", "VRPlusTraceAkimboOffhand", function(self, t, dt)

	if not alive(self._weapon_unit) then
		return
	end

	if self:hsm() then
		local hsm = self:hsm()
		local rot = hsm:rotation()

		self._weapon_unit:set_rotation(rot)
		local pos = Vector3()

		mvector3.set(pos, hsm:position())

		local weapon_id = self._weapon_unit:base() and self._weapon_unit:base().name_id
		local tweak = tweak_data.vr:get_offset_by_id(weapon_id)

		if tweak and tweak.position then
			mvector3.add(pos, tweak.position:rotate_with(self._weapon_unit:rotation()))
		end

		self._weapon_unit:set_position(pos)

	end

end)