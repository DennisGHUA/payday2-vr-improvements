--[[
	PlayerHandStateWeapon

	If view rotation is enabled, move gadget and firemode selectors
--]]

local function apply_thumbstick(self, t, dt)
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

local function is_gripping(self, t, dt)
	local controller = managers.vr:hand_state_machine():controller()
	local interact_btn = self:hsm():hand_id() == PlayerHand.LEFT and "interact_right" or "interact_left"

	if not VRPlusMod._data.comfort.weapon_assist_lock then
		return controller:get_input_bool(interact_btn)
	end

	-- TODO in the future weapon_assist_func
	local current = self:hsm():other_hand():current_state_name() == "weapon_assist"

	-- Use get_input_pressed not get_input_bool so we don't constantly toggle
	-- while holding the button down.
	if controller:get_input_pressed(interact_btn) then
		return not current
	end

	return current
end

local hand_to_hand = Vector3()
local other_hand = Vector3()
local weapon_pos = Vector3()
local pen = Draw:pen()

-- Almost compltetly identical to the default update method
-- but with grip_enable
function PlayerHandStateWeapon:update(t, dt)
	mvector3.set(weapon_pos, self:hsm():position())

	if self._weapon_kick and alive(self._weapon_unit) then
		mvector3.subtract(weapon_pos, self._weapon_unit:rotation():y() * self._weapon_kick)
		self._hand_unit:set_position(weapon_pos)
	end

	if self._wanted_weapon_kick then
		self._weapon_kick = self._weapon_kick or 0

		if self._weapon_kick < self._wanted_weapon_kick then
			self._weapon_kick = math.lerp(self._weapon_kick, self._wanted_weapon_kick, dt * tweak_data.vr.weapon_kick.kick_speed)
		else
			self._wanted_weapon_kick = 0
			self._weapon_kick = math.lerp(self._weapon_kick, self._wanted_weapon_kick, dt * tweak_data.vr.weapon_kick.return_speed)
		end
	end

	local controller = managers.vr:hand_state_machine():controller()
	local grip_enabled = is_gripping(self, t, dt)

	if self._can_switch_weapon_hand and controller:get_input_pressed("switch_hands") then
		self:hsm():set_default_state("idle")
		self:hsm():other_hand():set_default_state("weapon")
	end

	if alive(self._weapon_unit) then
		local is_assisting = self:hsm():other_hand():current_state_name() == "weapon_assist"

		if is_assisting and not self._pistol_grip then
			self._weapon_unit:set_rotation(Rotation(hand_to_hand, self._hand_unit:rotation():z()))
		else
			self._weapon_unit:set_rotation(self._hand_unit:rotation())
		end

		local assist_tweak = tweak_data.vr.weapon_assist.weapons[self._weapon_unit:base().name_id]
		assist_tweak = assist_tweak or self._default_assist_tweak
		self._pistol_grip = assist_tweak.pistol_grip

		if assist_tweak then
			if Global.draw_assist_point then
				local positions = {}

				if assist_tweak.position then
					table.insert(positions, assist_tweak.position)
				elseif assist_tweak.points then
					for _, point in ipairs(assist_tweak.points) do
						table.insert(positions, point.position)
					end
				end

				for _, position in ipairs(positions) do
					pen:sphere(weapon_pos + position:rotate_with(self._weapon_unit:rotation()) + (tweak_data.vr.weapon_offsets.weapons[self._weapon_unit:base().name_id] or tweak_data.vr.weapon_offsets.default).position:rotate_with(self._weapon_unit:rotation()), 5)
				end
			end

			if grip_enabled then
				mvector3.set(other_hand, self:hsm():other_hand():position())

				if not self._assist_position then
					self._assist_position = Vector3()

					if assist_tweak.position then
						mvector3.set(self._assist_position, assist_tweak.position)

						self._assist_grip = assist_tweak.grip or "grip_wpn"
					elseif assist_tweak.points then
						local closest_dis, closest = nil

						for _, assist_data in ipairs(assist_tweak.points) do
							local dis = mvector3.distance_sq(other_hand, weapon_pos + assist_data.position:rotate_with(self._weapon_unit:rotation()) + (tweak_data.vr.weapon_offsets.weapons[self._weapon_unit:base().name_id] or tweak_data.vr.weapon_offsets.default).position:rotate_with(self._weapon_unit:rotation()))

							if not closest_dis or dis < closest_dis then
								closest_dis = dis
								closest = assist_data
							end
						end

						if closest then
							mvector3.set(self._assist_position, closest.position)

							self._assist_grip = closest.grip or "grip_wpn"
						end
					end

					if not self._assist_position then
						debug_pause("Invalid assist tweak data for " .. self._weapon_unit:base().name_id)
					end
				end

				mvector3.subtract(other_hand, self._assist_position:with_y(0):rotate_with(self._hand_unit:rotation()))

				local other_hand_dis = mvector3.direction(hand_to_hand, self:hsm():position(), other_hand)

				if self._assist_position.y < 0 then
					mvector3.negate(hand_to_hand)
				end

				if not self._weapon_length then
					self._weapon_length = mvector3.length(self._assist_position) * 1.5
				end

				local max_dis = math.max(tweak_data.vr.weapon_assist.limits.max, self._weapon_length)

				if (tweak_data.vr.weapon_assist.limits.min < other_hand_dis or self._pistol_grip) and other_hand_dis < max_dis and (self._pistol_grip or (is_assisting and 0.4 or 0.9) < mvector3.dot(hand_to_hand, self._hand_unit:rotation():y())) then
					if not is_assisting and self:hsm():other_hand():can_change_state_by_name("weapon_assist") then
						self:hsm():other_hand():change_state_by_name("weapon_assist")
					end
				elseif is_assisting then
					self:hsm():other_hand():change_to_default()
					self._weapon_unit:set_rotation(self._hand_unit:rotation())
				end
			elseif self:hsm():other_hand():current_state_name() == "weapon_assist" then
				self:hsm():other_hand():change_to_default()
				self._weapon_unit:set_rotation(self._hand_unit:rotation())

				self._assist_position = nil
				self._assist_grip = nil
			end
		end

		local tweak = tweak_data.vr:get_offset_by_id(self._weapon_unit:base().name_id)

		if tweak and tweak.position then
			mvector3.add(weapon_pos, tweak.position:rotate_with(self._weapon_unit:rotation()))
			self._weapon_unit:set_position(weapon_pos)
			self._weapon_unit:set_moving(2)
		end
	end

	local touch_limit = 0.3

	if touch_limit < controller:get_input_axis("touchpad_primary").x then
		managers.hud:show_controller_assist("hud_vr_controller_gadget")
	elseif controller:get_input_axis("touchpad_primary").x < -touch_limit then
		managers.hud:show_controller_assist("hud_vr_controller_firemode")
	elseif touch_limit < controller:get_input_axis("touchpad_primary").y and self._can_switch_weapon_hand then
		managers.hud:show_controller_assist("hud_vr_controller_weapon_hand_switch")
	else
		managers.hud:hide_controller_assist()
	end

	apply_thumbstick(self, t, dt)
end
