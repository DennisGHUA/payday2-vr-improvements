--[[
	PlayerHandStateWeapon

	If view rotation is enabled, move gadget and firemode selectors
	Enable toggling gripping the weapon
	Update hand positions properly, using passed-in rotations for smoothness reasons
--]]

-- When rotation is enabled, show the hints for the gadget/firemode when the
-- thumbstick is in the correct direction
Hooks:PostHook(PlayerHandStateWeapon, "update", "VRPlusApplyWeaponThumbstickHints", function(self, t, dt)
	-- If turning is disabled, don't affect the mappings.
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

	local touch_limit = 0.3

	local controller = managers.vr:hand_state_machine():controller()
	local axis = controller:get_input_axis("touchpad_primary")

	if axis.y < -touch_limit then
		managers.hud:show_controller_assist("hud_vr_controller_firemode")
	elseif touch_limit < axis.y then
		managers.hud:show_controller_assist("hud_vr_controller_gadget")
	elseif axis.x < -touch_limit and self._can_switch_weapon_hand then
		managers.hud:show_controller_assist("hud_vr_controller_weapon_hand_switch")
	else
		managers.hud:hide_controller_assist()
	end
end)

-- Copypasted function from regular game
-- Changed to fix a crash
-- If nothing else, this will give clearer crash logs
function PlayerHandStateWeapon:at_enter(prev_state)
	PlayerHandStateWeapon.super.at_enter(self, prev_state)

	local player_unit = nil
	if managers.player then
		player_unit = managers.player:player_unit()
	end

	if player_unit and alive(player_unit) then
		player_unit:hand():sync_state()

		local weapon_unit = player_unit:inventory():equipped_unit()
		self._weapon_id = alive(weapon_unit) and weapon_unit:base().name_id

		self:_link_weapon(weapon_unit)
		player_unit:inventory():add_listener("PlayerHandStateWeapon_" .. tostring(self:hsm():hand_id()), nil, callback(self, self, "inventory_changed"))
	end

	if managers.hud then
		managers.hud:link_ammo_hud(self._hand_unit, self:hsm():hand_id())
		managers.hud:ammo_panel():set_visible(true)
	end
	
	self._hand_unit:melee():set_weapon_unit(self._weapon_unit)

	self._weapon_length = nil

	self:hsm():enter_controller_state("weapon")
	self:hsm():other_hand():enter_controller_state("empty")

	self._default_assist_tweak = {
		pistol_grip = true,
		grip = "idle_wpn",
		position = Vector3(0, 5, -5)
	}
	self._pistol_grip = false
	self._assist_position = nil
	self._grip_toggle = nil

	if alive(self._weapon_unit) or self._is_bow then
		local sequence = self._sequence
		local tweak = self._is_bow and tweak_data.vr:get_offset_by_id("bow", self._weapon_id) or tweak_data.vr:get_offset_by_id(self._weapon_id)

		if tweak.grip then
			sequence = tweak.grip
		end

		if self._hand_unit and sequence and self._hand_unit:damage():has_sequence(sequence) then
			self._hand_unit:damage():run_sequence_simple(sequence)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Weapon movement lag fix (Update 247 / Diesel 3.0 regression)
--
-- Vanilla writes the dominant-hand weapon transform every frame, but the
-- weapon model ends up up to a second or two behind the hand while the player
-- moves through the world (locomotion or warp). The gadget laser is drawn
-- straight from set_gadget_position() and is therefore the one thing that
-- tracks correctly.
--
-- The historical VRPlus fix for this class of bug (9dc0cba, "Fix weapon
-- movement/rotation lag") kept the *fresh* controller-derived weapon transform
-- on the state so it could be passed on without depending on what the engine
-- has actually applied to the weapon unit. We restore that behaviour here:
--
--  * init caches a scratch __weapon_position/__weapon_rotation on the state.
--  * after the vanilla update the weapon is re-written at the transform the
--    hand says it should be at this frame (same approach as the akimbo
--    offhand fix, which writes directly and is immediate).
--  * the assist hand (playerhandstateweaponassist.lua) anchors itself to
--    these cached fresh values instead of the lagging weapon unit transform.
-- ---------------------------------------------------------------------------
Hooks:PostHook(PlayerHandStateWeapon, "init", "VRPlusInitWeaponTransformCache", function(self)
	if not self.__weapon_position then
		self.__weapon_position = Vector3()
	end

	if not self.__weapon_rotation then
		self.__weapon_rotation = Rotation()
	end
end)

Hooks:PostHook(PlayerHandStateWeapon, "update", "VRPlusFixWeaponLag", function(self, t, dt)
	if not alive(self._weapon_unit) or not self.__weapon_position then
		return
	end

	-- The fresh rotation the vanilla update derived from the hand state this
	-- frame. When the weapon is aimed at the assist hand the vanilla code
	-- writes a look-at rotation instead, so keep whatever the weapon carries
	-- in that case.
	local is_assisting = self:hsm():other_hand():current_state_name() == "weapon_assist"
	local weapon_rot = self:hsm():rotation()

	if is_assisting and not self._pistol_grip then
		weapon_rot = self._weapon_unit:rotation()
	end

	mrotation.set_zero(self.__weapon_rotation)
	mrotation.multiply(self.__weapon_rotation, weapon_rot)

	local pos = self.__weapon_position

	mvector3.set(pos, self:hsm():position())

	if self._weapon_kick then
		mvector3.subtract(pos, self.__weapon_rotation:y() * self._weapon_kick)
	end

	local tweak = tweak_data.vr:get_offset_by_id(self._weapon_id)

	if tweak and tweak.position then
		mvector3.add(pos, tweak.position:rotate_with(self.__weapon_rotation))
	end

	-- Write the fresh target directly, exactly like the akimbo offhand fix,
	-- instead of leaving the weapon on whatever smoothed transform the
	-- engine has buffered for the unit.
	self._weapon_unit:set_position(pos)
	self._weapon_unit:base():set_gadget_position(pos)
end)
