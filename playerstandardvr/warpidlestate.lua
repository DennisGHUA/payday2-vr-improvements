--[[
	WarpIdleState

	Disable warp pointer thing, and allow jumping and sprinting with a motion controller.
--]]

function WarpIdleState:transition()
	-- Always stay on Idle (this does not affect the special ladder
	-- states, etc - only using the thumbpad to switch to WarpTargetState)
	return
end

local function custom_move_direction(self, stick_motion)
	self._stick_move = stick_motion

	if self._state_data.on_zipline then
		return
	end

	if mvector3.length(self._stick_move) < (VRPlusMod._data.deadzone / 100) or self:_interacting() or self:_does_deploying_limit_movement() then
		self._stick_move = nil
	end

	if not self._stick_move then
		self._move_dir = nil
		self._normal_move_dir = nil
		return
	end

	local ladder_unit = self._unit:movement():ladder_unit()

	if alive(ladder_unit) then
		local ladder_ext = ladder_unit:ladder()
		self._move_dir = mvector3.copy(self._stick_move)
		self._normal_move_dir = mvector3.copy(self._move_dir)
		local cam_flat_rot = Rotation(self._cam_fwd_flat, math.UP)

		mvector3.rotate_with(self._normal_move_dir, cam_flat_rot)

		local cam_rot = Rotation(self._cam_fwd, self._ext_camera:rotation():z())

		mvector3.rotate_with(self._move_dir, cam_rot)

		local up_dot = math.dot(self._move_dir, ladder_ext:up())
		local w_dir_dot = math.dot(self._move_dir, ladder_ext:w_dir())
		local normal_dot = math.dot(self._move_dir, ladder_ext:normal()) * -1
		local normal_offset = ladder_ext:get_normal_move_offset(self._unit:movement():m_pos())

		mvector3.set(self._move_dir, ladder_ext:up() * (up_dot + normal_dot))
		mvector3.add(self._move_dir, ladder_ext:w_dir() * w_dir_dot)
		mvector3.add(self._move_dir, ladder_ext:normal() * normal_offset)
	else
		self._move_dir = mvector3.copy(self._stick_move)
		local cam_flat_rot = Rotation(self._cam_fwd_flat, math.UP)

		mvector3.rotate_with(self._move_dir, cam_flat_rot)

		self._normal_move_dir = mvector3.copy(self._move_dir)
	end
end

-- Cloned directly from the flat version of playerstandard
-- TODO get the old function somehow
function orig_start_action_jump(self, t, action_start_data)
	if self._running and not self.RUN_AND_RELOAD and not self._equipped_unit:base():run_and_shoot_allowed() then
		self:_interupt_action_reload(t)
		self._ext_camera:play_redirect(self:get_animation("stop_running"), self._equipped_unit:base():exit_run_speed_multiplier())
	end

	self:_interupt_action_running(t)

	self._jump_t = t
	local jump_vec = action_start_data.jump_vel_z * math.UP

	self._unit:mover():jump()

	if self._move_dir then
		local move_dir_clamp = self._move_dir:normalized() * math.min(1, self._move_dir:length())
		self._last_velocity_xy = move_dir_clamp * action_start_data.jump_vel_xy
		self._jump_vel_xy = mvector3.copy(self._last_velocity_xy)
	else
		self._last_velocity_xy = Vector3()
	end

	self:_perform_jump(jump_vec)
end

local function ps_trigger_jump(self, t)
	if not self:_can_jump() then return end

	-- Make the player jump
	local action_forbidden = self._jump_t and t < self._jump_t + 0.55
			action_forbidden = action_forbidden or self._unit:base():stats_screen_visible() or
			self._state_data.in_air or self:_interacting() or self:_on_zipline() or
			self:_does_deploying_limit_movement() or self:_is_using_bipod()
	if action_forbidden then return false end

	local action_start_data = {}
	local jump_vel_z = tweak_data.player.movement_state.standard.movement.jump_velocity.z
	action_start_data.jump_vel_z = jump_vel_z

	if self._move_dir then
		local is_running = self._running and self._unit:movement():is_above_stamina_threshold() and t - self._start_running_t > 0.4
		local jump_vel_xy = tweak_data.player.movement_state.standard.movement.jump_velocity.xy[is_running and "run" or "walk"]
		action_start_data.jump_vel_xy = jump_vel_xy

		if is_running then
			self._unit:movement():subtract_stamina(tweak_data.player.movement_state.stamina.JUMP_STAMINA_DRAIN)
		end
	end

	new_action = orig_start_action_jump(self, t, action_start_data)
end

function WarpIdleState:update(t)
	-- Update sprinting
	local state = self.params.playerstate
	local hand = self.params.unit:hand():warp_hand()
	local controller = state._unit:base():controller() -- TODO use self.params.controller - why is it nil!?
	local sprint_button = (hand == "left" and "warp_left") or "warp_right"
	local sprit_pressed = controller:get_input_bool(sprint_button)
	custom_move_direction(state, controller:get_input_axis("touchpad_warp_target"))

	-- Toggle system
	if VRPlusMod._data.rift_stickysprint then
		-- If the button is being held down, start the hold timer
		if sprit_pressed and not self._click_time_start then
			self._click_time_start = t
		end

		if self._click_time_start == -1 then
			-- Wait for the user to release the button
		elseif self._click_time_start then
			local timer = t - self._click_time_start
			if timer > VRPlusMod._data.sprint_time then
				self._click_time_start = -1

				state._running_wanted = not state._running
				state.__stop_running = not state._running_wanted
			elseif not sprit_pressed then
				ps_trigger_jump(state, t)
			end
		end

		if not sprit_pressed then
			self._click_time_start = nil
		end
	else
		state._running_wanted = sprit_pressed
		state.__stop_running = not state._running_wanted
	end
end
