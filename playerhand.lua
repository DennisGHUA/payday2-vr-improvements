--[[
	PlayerHand

	Split the hand update cycle into three pieces:
	 * Set the position of both hands
	 * Update both hands
	 * post_update and end_update both hands

	This makes it possible for hands to depend on each other's actions, and allows for
	fixing the weapon position/rotation lag.
--]]

local old_update_controllers = PlayerHand._update_controllers
function PlayerHand:_update_controllers(t, dt)
	local hmd_pos = VRManager:hmd_position()
	local current_height = hmd_pos.z

	mvector3.set_z(hmd_pos, 0)

	local ghost_position = self._unit_movement_ext:ghost_position()

	if self._vr_controller then
		-- Update controller positions and update the states in seperate passes
		-- Fixes #38
		for i, controller in ipairs(self._hand_data) do
			local pos, rot = self._vr_controller:pose(i - 1)
			rot = self._base_rotation * rot
			pos = pos - hmd_pos

			mvector3.rotate_with(pos, self._base_rotation)

			pos = pos + ghost_position

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
		end

		for i, controller in ipairs(self._hand_data) do
			controller.state_machine:update(t, dt)
		end
		
		for i, controller in ipairs(self._hand_data) do
			-- Lets states move data between hands without unidirectional delays
			local state = controller.state_machine:current_state()
			if state and state.post_update then
				state:post_update(t, dt)
			end

			controller.state_machine:end_update(t, dt)

			if self._scheculed_wall_checks and self._scheculed_wall_checks[i] and self._scheculed_wall_checks[i].t < t then
				local custom_obj = self._scheculed_wall_checks[i].custom_obj
				self._scheculed_wall_checks[i] = nil

				if not self:check_hand_through_wall(i, custom_obj) then
					controller.unit:damage():run_sequence_simple(self:current_hand_state(i)._sequence)
				end
			end
		end
	end
	
	-- Update everything but the motion controllers
	local old_vr_controller = self._vr_controller
	self._vr_controller = false
	old_update_controllers(self, t, dt)
	self._vr_controller = old_vr_controller
end
