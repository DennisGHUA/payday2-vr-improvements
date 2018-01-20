--[[
	PlayerHand

	Split the hand update cycle into three pieces:
	 * Set the position of both hands
	 * Update both hands
	 * post_update and end_update both hands

	This makes it possible for hands to depend on each other's actions, and allows for
	fixing the weapon position/rotation lag.

	This also uses the player's movement to adjust the hand positions, repecting
	the crouch button.
--]]

function PlayerHand:_update_controllers(t, dt)
	local hmd_pos = VRManager:hmd_position()
	local current_height = hmd_pos.z

	mvector3.set_z(hmd_pos, 0)

	local ghost_position = self._unit_movement_ext:ghost_position()

	if self._vr_controller then
		for i, controller in ipairs(self._hand_data) do
			local pos, rot = self._vr_controller:pose(i - 1)
			self._unit_movement_ext:__affect_vrobj_position(pos) -- Move the hands if in crouch mode
			rot = self._base_rotation * rot
			pos = pos - hmd_pos

			mvector3.rotate_with(pos, self._base_rotation)

			pos = pos + ghost_position

			mrotation.set_zero(controller.rotation_raw)
			mrotation.multiply(controller.rotation_raw, rot)
			mrotation.multiply(controller.rotation_raw, controller.base_rotation_controller)
			mrotation.multiply(rot, controller.base_rotation)

			controller.rotation = rot
			pos = pos + controller.base_position:rotate_with(controller.rotation)
			controller.position = pos
			local forward = Vector3(0, 1, 0)
			controller.forward = forward:rotate_with(controller.rotation)

			controller.unit:set_position(pos)
			controller.unit:set_rotation(rot)
			controller.state_machine:set_position(pos)
			controller.state_machine:set_rotation(rot)

			if self._scheculed_wall_checks and self._scheculed_wall_checks[i] and self._scheculed_wall_checks[i].t < t then
				local custom_obj = self._scheculed_wall_checks[i].custom_obj
				self._scheculed_wall_checks[i] = nil

				if not self:check_hand_through_wall(i, custom_obj) then
					controller.unit:damage():run_sequence_simple(self:current_hand_state(i)._sequence)
				end
			end
		end

		for _, controller in ipairs(self._hand_data) do
			controller.state_machine:update(t, dt)
		end

		self._shared_transition_queue:do_state_change()
	end

	local rot = VRManager:hmd_rotation()
	rot = self._base_rotation * rot
	local forward = Vector3(0, 1, 0)
	local up = Vector3(0, 0, 1)

	mvector3.rotate_with(forward, rot)
	mvector3.rotate_with(up, rot)

	local v = forward

	if forward.y < 0.5 then
		v = up
	end

	mvector3.set_z(v, 0)
	mvector3.normalize(v)
	self._shadow_unit:set_position(ghost_position - v * 30 + Vector3(0, 0, 5))

	local max_angle = managers.vr:get_setting("belt_snap")
	local angle = rot:rotation_difference(Rotation(self._belt_yaw, 0, 0), Rotation(rot:yaw(), 0, 0)):yaw()
	local abs_angle = math.abs(angle)
	local distance = mvector3.distance_sq(self._prev_ghost_position, ghost_position)

	if rot:pitch() > -35 or max_angle < abs_angle or distance > 1600 then
		self._prev_ghost_position = mvector3.copy(ghost_position)
		self._belt_yaw = rot:yaw()
	end

	local belt_rot = Rotation(self._belt_yaw, 0, 0)
	local belt_offset = Vector3(0, managers.vr:get_setting("belt_distance"),
		current_height * (self._custom_belt_height_ratio or managers.vr:get_setting("belt_height_ratio"))
	):rotate_with(belt_rot)

	self._unit_movement_ext:__affect_vrobj_position(belt_offset)

	if self._unit_movement_ext:current_state().__bttn_ducking then
		mvector3.set_z(belt_offset, 15)
	end

	self._belt_unit:set_position(ghost_position + belt_offset)
	self._belt_unit:set_rotation(belt_rot)

	local look_dot = math.clamp(mvector3.dot(rot:y(), Vector3(0, 0, -1)), 0, 1) - 0.6

	managers.hud:belt():set_alpha(look_dot * 1.5)

	for i = 1, 2, 1 do
		local closest = math.huge

		if managers.hud:belt():visible() then
			for _, interact_name in ipairs(managers.hud:belt():valid_interactions()) do
				local interact_pos = managers.hud:belt():get_interaction_point(interact_name)
				closest = math.min(closest, mvector3.distance_sq(self:hand_unit(i):position(), interact_pos))
			end
		end

		self:set_belt_active(closest < 100, i)
	end
end
