--[[
	PlayerStandardVR

	Change the movement method to thumbstick/trackpad locomotion
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

-- The VR implementation of this doesn't take sprinting into
-- account - therefore the player moves at sprinting speed nomatter
-- what. Fixes #1
-- TODO find some way to avoid overridding the whole method
function PlayerStandard:_get_max_walk_speed(t)
	-- Note: this is identical to the non-vr version of this function
	local speed_tweak = self._tweak_data.movement.speed
	local movement_speed = speed_tweak.STANDARD_MAX
	local speed_state = "walk"

	if self._state_data.in_steelsight and not managers.player:has_category_upgrade("player", "steelsight_normal_movement_speed") then
			movement_speed = speed_tweak.STEELSIGHT_MAX
			speed_state = "steelsight"
	elseif self:on_ladder() then
			movement_speed = speed_tweak.CLIMBING_MAX
			speed_state = "climb"
	elseif self._state_data.ducking then
			movement_speed = speed_tweak.CROUCHING_MAX
			speed_state = "crouch"
	elseif self._state_data.in_air then
			movement_speed = speed_tweak.INAIR_MAX
			speed_state = nil
	elseif self._running then
			movement_speed = speed_tweak.RUNNING_MAX
			speed_state = "run"
	end

	movement_speed = managers.crime_spree:modify_value("PlayerStandard:GetMaxWalkSpeed", movement_speed, self._state_data, speed_tweak)
	local morale_boost_bonus = self._ext_movement:morale_boost()
	local multiplier = managers.player:movement_speed_multiplier(speed_state, speed_state and morale_boost_bonus and morale_boost_bonus.move_speed_bonus, nil, self._ext_damage:health_ratio())
	local apply_weapon_penalty = true

	if self:_is_meleeing() then
			local melee_entry = managers.blackmarket:equipped_melee_weapon()
			apply_weapon_penalty = not tweak_data.blackmarket.melee_weapons[melee_entry].stats.remove_weapon_movement_penalty
	end

	if alive(self._equipped_unit) and apply_weapon_penalty then
			multiplier = multiplier * self._equipped_unit:base():movement_penalty()
	end

	if managers.player:has_activate_temporary_upgrade("temporary", "increased_movement_speed") then
			multiplier = multiplier * managers.player:temporary_upgrade_value("temporary", "increased_movement_speed", 1)
	end

	local final_speed = movement_speed * multiplier
	self._cached_final_speed = self._cached_final_speed or 0

	if final_speed ~= self._cached_final_speed then
		self._cached_final_speed = final_speed

		self._ext_network:send("action_change_speed", final_speed)
	end

	return final_speed
end

function PlayerStandard:_check_action_run(t, input)
	-- Don't read input for _running_wanted - this is updated on the hand controller.
	
	-- Don't do anything if we're not moving. Saves on crashes.
	if not self._move_dir then
		self._running_wanted = false
		self.__stop_running = false
	end
	
	if self._running and self.__stop_running then
		self:_end_action_running(t)
	elseif not self._running and self._running_wanted then
		self:_start_action_running(t)
	end
end

-- Prevent crashes when stopping sprinting by letting go of the stick
local old_can_run_directional = PlayerStandard._can_run_directional
function PlayerStandard:_can_run_directional()
	return self._stick_move and old_can_run_directional(self) or false
end

-- Hand ourselves ('playerstate') to the states
local old_init = PlayerStandardVR.init
function PlayerStandardVR:init(unit)
	old_init(self, unit)

	self._warp_state_machine = CoreFiniteStateMachine.FiniteStateMachine:new(WarpIdleState, "params", {
			state_data = self._state_data,
			unit = unit,
			controller = controller,
			playerstate = self
	})

	self._warp_state_machine:set_debug(false)
end

local function do_rotation(self, t, dt)
	local mode = VRPlusMod._data.turning_mode
	if mode == VRPlusMod.C.TURNING_OFF then return end

	local controller = self._unit:base():controller()
	local axis = controller:get_input_axis("touchpad_primary")
	local rot = VRManager:hmd_rotation() -- TODO don't do this

	if not axis then return end

	if mode == VRPlusMod.C.TURNING_SMOOTH then
		local deadzone = 0.75 -- TODO add option

		if math.abs(axis.x) > deadzone then
			-- Scale from nothing to 100% over the course of the active zone
			local amt = (axis.x > 0) and (axis.x - deadzone) or (axis.x + deadzone)
			amt = amt * 1/(1-deadzone)

			-- One full revolution per second on maxed stick
			self.__yaw_rotation_offset = (self.__yaw_rotation_offset or 0) + (dt * 360 / 2 * -amt)
			self:set_base_rotation(Rotation(rot:yaw() + self.__yaw_rotation_offset, 0, 0))
		end
	else
		-- Snap turning
		-- TODO move to options GUI
		local turn, nonturn = 0.75, 0.5
		local delay = 0.25 -- Delay before turning
		local rotation_amt = 30 -- Rotation in degrees

		-- Apply cooldown
		self.__snap_rotate_timer = math.max(-1, (self.__snap_rotate_timer or 0) - dt)

		if math.abs(axis.x) > turn and self.__snap_rotate_timer < 0 then
			self.__snap_rotate_timer = delay
			local amt = ((axis.x > 0) and 1 or -1) * rotation_amt

			self.__yaw_rotation_offset = (self.__yaw_rotation_offset or 0) - amt
			self:set_base_rotation(Rotation(rot:yaw() + self.__yaw_rotation_offset, 0, 0))
		end
	end
end

local old_update = PlayerStandardVR.update
function PlayerStandardVR:update(t, dt)
	do_rotation(self, t, dt) -- Handle smooth/snap rotation

	old_update(self, t, dt)
	
	-- Reset all movement-related stuff so nothing blows up
	-- if the idle controller disappears (both hands are busy)
	-- Very important we do this after everything else is done updating.
	self._move_dir = nil
	self._normal_move_dir = nil
end

-- Handled in WarpIdleState:update and custom_move_direction
function PlayerStandardVR:_determine_move_direction() end

local mvec_prev_pos = Vector3() -- Our custom one
local mvec_achieved_walk_vel = Vector3()
local mvec_move_dir_normalized = Vector3()
local function inject_movement(self, t, dt, pos_new)
	local anim_data = self._unit:anim_data()
	local weapon_id = alive(self._equipped_unit) and self._equipped_unit:base() and self._equipped_unit:base():get_name_id()
	local weapon_tweak_data = weapon_id and tweak_data.weapon[weapon_id]
	self._target_headbob = self._target_headbob or 0
	self._headbob = self._headbob or 0
	
	mvector3.set(mvec_prev_pos, pos_new)

	if self._state_data.on_zipline and self._state_data.zipline_data.position then
		-- Do nothing
	elseif self._move_dir then
		local enter_moving = not self._moving
		self._moving = true

		if enter_moving then
			self._last_sent_pos_t = t

			self:_update_crosshair_offset()
		end

		local WALK_SPEED_MAX = self:_get_max_walk_speed(t)

		mvector3.set(mvec_move_dir_normalized, self._move_dir)
		mvector3.normalize(mvec_move_dir_normalized)

		local wanted_walk_speed = WALK_SPEED_MAX * math.min(1, self._move_dir:length())
		local acceleration = self._state_data.in_air and 700 or self._running and 5000 or 3000
		local achieved_walk_vel = mvec_achieved_walk_vel

		if self._jump_vel_xy and self._state_data.in_air and mvector3.dot(self._jump_vel_xy, self._last_velocity_xy) > 0 then
			local input_move_vec = wanted_walk_speed * self._move_dir
			local jump_dir = mvector3.copy(self._last_velocity_xy)
			local jump_vel = mvector3.normalize(jump_dir)
			local fwd_dot = jump_dir:dot(input_move_vec)

			if fwd_dot < jump_vel then
				local sustain_dot = (input_move_vec:normalized() * jump_vel):dot(jump_dir)
				local new_move_vec = input_move_vec + jump_dir * (sustain_dot - fwd_dot)

				mvector3.step(achieved_walk_vel, self._last_velocity_xy, new_move_vec, 700 * dt)
			else
				mvector3.multiply(mvec_move_dir_normalized, wanted_walk_speed)
				mvector3.step(achieved_walk_vel, self._last_velocity_xy, wanted_walk_speed * self._move_dir:normalized(), acceleration * dt)
			end

			local fwd_component = nil
		else
			mvector3.multiply(mvec_move_dir_normalized, wanted_walk_speed)
			mvector3.step(achieved_walk_vel, self._last_velocity_xy, mvec_move_dir_normalized, acceleration * dt)
		end

		if mvector3.is_zero(self._last_velocity_xy) then
			mvector3.set_length(achieved_walk_vel, math.max(achieved_walk_vel:length(), 100))
		end

		mvector3.set(pos_new, achieved_walk_vel)
		mvector3.multiply(pos_new, dt)
		mvector3.add(pos_new, mvec_prev_pos)

		self._target_headbob = self:_get_walk_headbob()
		self._target_headbob = self._target_headbob * self._move_dir:length()

		if weapon_tweak_data and weapon_tweak_data.headbob and weapon_tweak_data.headbob.multiplier then
			self._target_headbob = self._target_headbob * weapon_tweak_data.headbob.multiplier
		end
--[[	elseif not mvector3.is_zero(self._last_velocity_xy) then
		local decceleration = self._state_data.in_air and 250 or math.lerp(2000, 1500, math.min(self._last_velocity_xy:length() / tweak_data.player.movement_state.standard.movement.speed.RUNNING_MAX, 1))
		local achieved_walk_vel = math.step(self._last_velocity_xy, Vector3(), decceleration * dt)

		mvector3.set(pos_new, achieved_walk_vel)
		mvector3.multiply(pos_new, dt)
		mvector3.add(pos_new, mvec_prev_pos)

		self._target_headbob = 0]]
	elseif self._moving then
		self._target_headbob = 0
		self._moving = false

		--self:_update_crosshair_offset()
	end

	--[[if self._headbob ~= self._target_headbob then
		local ratio = 4

		if weapon_tweak_data and weapon_tweak_data.headbob and weapon_tweak_data.headbob.speed_ratio then
			ratio = weapon_tweak_data.headbob.speed_ratio
		end

		self._headbob = math.step(self._headbob, self._target_headbob, dt / ratio)

		self._ext_camera:set_shaker_parameter("headbob", "amplitude", self._headbob)
	end]]

	--[[if pos_new then
		self._unit:movement():set_position(pos_new)
		mvector3.set(self._last_velocity_xy, pos_new)
		mvector3.subtract(self._last_velocity_xy, self._pos)

		if not self._state_data.on_ladder and not self._state_data.on_zipline then
			mvector3.set_z(self._last_velocity_xy, 0)
		end

		mvector3.divide(self._last_velocity_xy, dt)
	else
		mvector3.set_static(self._last_velocity_xy, 0, 0, 0)
	end]]
end

-- These aren't used elsewhere, so it's safe to duplicate them
-- they're just to prevent reallocating vectors each frame
local mvec_pos_initial = Vector3()
local mvec_pos_new = Vector3()
local mvec_hmd_delta = Vector3()

local old_update_movement = PlayerStandardVR._update_movement
function PlayerStandardVR:_update_movement(t, dt)
	local pos_new = mvec_pos_new
	local init_pos_ghost = mvec_pos_initial

	mvector3.set(pos_new, self._ext_movement:ghost_position())

	if self._state_data.warping and self._state_data._warp_target then
		local dir = self._state_data._warp_target - pos_new
		local dist = mvector3.normalize(dir)
		local warp_len = dt*self.WARP_SPEED

		if dist <= warp_len or dist == 0 then
			mvector3.set(pos_new, self._state_data._warp_target)
			self._end_action_warp(self)
		elseif 3 < t - self._state_data._warp_start_time then
			self._end_action_warp(self)
		else
			mvector3.add(pos_new, dir*warp_len)
		end
	elseif self._state_data.on_zipline and self._state_data.zipline_data.position then
		local rot = Rotation()

		mrotation.set_look_at(rot, self._state_data.zipline_data.zipline_unit:zipline():current_direction(), math.UP)

		self._ext_camera:camera_unit():base()._output_data.rotation = rot

		mvector3.set(pos_new, self._state_data.zipline_data.position)
	else
		if not self._state_data.last_warp_pos or self.MOVEMENT_DISTANCE_LIMIT*self.MOVEMENT_DISTANCE_LIMIT < mvector3.distance_sq(self._state_data.last_warp_pos, pos_new) then
			mvector3.set_z(pos_new, self._pos.z)
		end

		local hmd_delta = mvec_hmd_delta

		if not self._state_data._block_input then
			mvector3.set(hmd_delta, self._ext_movement:hmd_delta())
		else
			mvector3.set_zero(hmd_delta)
		end

		mvector3.set_z(hmd_delta, 0)
		mvector3.rotate_with(hmd_delta, self._camera_base_rot)
		mvector3.add(pos_new, hmd_delta)
	end
	
	-- only start tracking velocity from here - the HMD movement doesn't count.
	mvector3.set(init_pos_ghost, pos_new)

	inject_movement(self, t, dt, pos_new)

	if self._state_data.on_ladder then
		local unit_position = math.dot(pos_new - self._state_data.ladder.current_position, self._state_data.ladder.w_dir)*self._state_data.ladder.w_dir + self._state_data.ladder.current_position

		self._ext_movement:set_ghost_position(pos_new, unit_position)
		mvector3.set(pos_new, unit_position)
	else
		self._ext_movement:set_ghost_position(pos_new)
	end

	if self._state_data.warping then
		mvector3.set_z(self._last_velocity_xy, 0)
	else
		mvector3.set(self._last_velocity_xy, pos_new)
		mvector3.subtract(self._last_velocity_xy, init_pos_ghost)
		mvector3.divide(self._last_velocity_xy, dt)
	end

	local cur_pos = pos_new or self._pos

	self._update_network_jump(self, cur_pos, false, t, dt)
	self._update_network_position(self, t, dt, cur_pos, pos_new)

	local move_dis = mvector3.distance_sq(cur_pos, self._last_sent_pos)

	if self.is_network_move_allowed(self) and (22500 < move_dis or (400 < move_dis and (1.5 < t - self._last_sent_pos_t or not pos_new))) then
		self._ext_network:send("action_walk_nav_point", cur_pos)
		mvector3.set(self._last_sent_pos, cur_pos)

		self._last_sent_pos_t = t
	end

	if self._is_jumping then
		self._jump_timer = self._jump_timer + dt
	end
	
	-- old_update_movement(self, t, dt)
end

-- Respect _can_duck, to prevent ducking during mask-off
local old_start_action_ducking = PlayerStandardVR._start_action_ducking
function PlayerStandardVR:_start_action_ducking(t)
	if not self:_can_duck() then return end
	old_start_action_ducking(self, t)
end

-- Permission functions that are overridden by the mask off state
-- define them so we can check them later
function PlayerStandardVR:_can_jump() return true end
function PlayerStandardVR:_can_duck() return true end
