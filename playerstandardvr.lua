--[[
	PlayerStandardVR

	Change the movement method to thumbstick/trackpad locomotion
--]]

dofile(ModPath .. "playerstandardvr/warpidlestate.lua")
dofile(ModPath .. "playerstandardvr/warptargetstate.lua")
dofile(ModPath .. "playerstandardvr/ladders.lua")

-- Apply the movement speed cap
local old_get_max_walk_speed = PlayerStandard._get_max_walk_speed
function PlayerStandard:_get_max_walk_speed(...)
	local final_speed = old_get_max_walk_speed(self, ...)

	-- In the vanilla movement modes the airborne horizontal motion is recomputed
	-- every frame from the stick axis * _get_max_walk_speed, and while airborne
	-- that speed is INAIR_MAX regardless of whether the jump was a sprint-jump.
	-- While airborne after a jump, feed the jump's launch speed instead - the
	-- 'run' jump velocity when sprinting, the 'walk' jump velocity otherwise.
	-- (Locomotion mode skips this: it has its own launch-momentum air physics via
	-- _last_velocity_xy/_jump_vel_xy in inject_movement.)
	if not VRPlusMod._data.movement_locomotion and self._movement_input and VRPlusMod._data.jump_enabled ~= false and self._state_data and self._state_data.in_air and self._jump_vel_xy then
		local jump_speed = mvector3.length(self._jump_vel_xy)
		if jump_speed > 0 then
			final_speed = jump_speed
		end
	end

	-- Apply a speed cap, as per the comfort options
	if VRPlusMod._data.comfort.max_movement_speed_enable then
		final_speed = math.min(final_speed, VRPlusMod._data.comfort.max_movement_speed)
	end

	return final_speed
end

-- Applies the "Sprinting" (sprint_mode) setting: Disable / Long-click to toggle
-- (SPRINT_STICKY) / Hold-click to sprint (SPRINT_HOLD). Turns the raw run input
-- into _running_wanted + __stop_running, which _check_action_run consumes.
-- Shared between locomotion mode (WarpIdleState) and vanilla movement fallback.
function PlayerStandard:apply_sprint_mode(t, sprint_pressed)
	local mode = VRPlusMod._data.sprint_mode

	-- If the sprint button is being held down, start the hold timer
	if sprint_pressed and not self._sprint_click_start then
		self._sprint_click_start = t
	end

	-- the clock is running, and more than _data.sprint_time seconds have elapsed
	local held_down = self._sprint_click_start and (t - self._sprint_click_start) > VRPlusMod._data.sprint_time

	if mode == VRPlusMod.C.SPRINT_STICKY then
		-- Long-click to toggle: a fresh long-press flips the latched sprint state.
		-- Fire only once per press (the rising edge) - while the button is held
		-- down held_down stays true, so without the latch it would keep toggling
		-- every frame. On the next long-press it flips again, turning sprint off.
		if held_down and not self._sprint_long_fired then
			self._sprint_long_fired = true
			self._sprint_sticky = not self._sprint_sticky
		end

		-- Keep the latched state applied every frame. The locomotion path clears
		-- _running_wanted whenever the stick stops moving, so we re-assert it here
		-- while input is live so a second long-click can turn sprint off again.
		self._running_wanted = self._sprint_sticky and true or false
		self.__stop_running = not self._running_wanted
	elseif mode == VRPlusMod.C.SPRINT_HOLD then
		self._running_wanted = held_down
		self.__stop_running = not self._running_wanted
	else
		-- Sprinting disabled (SPRINT_OFF, or any unknown value)
		self._running_wanted = false
		self.__stop_running = true
	end

	-- The press (and any completed long-click edge) is finished once the button is
	-- released - clear the hold timer so the next press is treated as a fresh
	-- potential long-click toggling the sticky state again.
	if not sprint_pressed then
		self._sprint_click_start = nil
		self._sprint_long_fired = false
	end
end

function PlayerStandard:_check_action_run(t, input)
	-- Vanilla movement (locomotion off, e.g. the vanilla Dash+Direct mode): fall
	-- back to vanilla-style run handling that reads the live "run" input and routes
	-- it through the mod's "Sprinting" mode (Off / Long-click toggle / Hold-click).
	-- The locomotion path below is driven by _running_wanted/_stick_move which is
	-- only fed by WarpIdleState:update - and that function returns early whenever
	-- locomotion is disabled - so without this branch sprinting could never start,
	-- no matter what the Sprinting/Motion Controller options or Advanced Controls
	-- Manager bindings said.
	if not VRPlusMod._data.movement_locomotion and self._movement_input then
		-- "Off": do not interfere - use the vanilla default sprint handling
		-- untouched. In Dash+Direct that is the vanilla run input read straight
		-- from _movement_input, exactly like the committed upstream fix.
		if VRPlusMod._data.sprint_mode == VRPlusMod.C.SPRINT_OFF then
			local run_state = self._movement_input:state().run

			if not self._running and run_state then
				self:_start_action_running(t, input)
			elseif self._running and not run_state then
				self:_end_action_running(t)
			end

			return
		end

		local sprint_pressed = self._controller and self._controller:get_input_bool("run") or nil

		self:apply_sprint_mode(t, sprint_pressed)

		-- Dash+Direct has no _move_dir (that field is locomotion-only), so sticky
		-- sprint has nothing to clear it. Mirror locomotion's "stop running when
		-- movement stops" gate through the analog input: while direct movement is
		-- active we keep the sprint-mode state, otherwise it is cancelled. The only
		-- exception is the moment of a touchpad toggle-click itself (Vive) - the pad
		-- is centred then, so we let the click finish before the gate applies.
		if not self._movement_input:is_movement_walk() and not (self._sprint_sticky and sprint_pressed) then
			self._running_wanted = false
			self.__stop_running = true
		end

		-- Start/stop running from the sprint-mode flags, mirroring the locomotion path
		if self._running and self.__stop_running then
			self:_end_action_running(t)
		elseif not self._running and self._running_wanted then
			self:_start_action_running(t, input)
		end

		return
	end

	-- Don't read input for _running_wanted - this is updated on the hand controller.

	-- Don't do anything if we're not moving. Saves on crashes, eg when downed.
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
-- (locomotion mode). In the vanilla movement modes (Dash / Direct / Dash+Direct)
-- with the mod's locomotion disabled there is no _stick_move field at all, so
-- directional running is always allowed - otherwise _update_running_timers would
-- interrupt any sprint immediately.
local old_can_run_directional = PlayerStandard._can_run_directional
function PlayerStandard:_can_run_directional()
	if not VRPlusMod._data.movement_locomotion then
		return true
	end

	-- Sticky sprint must survive the actual toggle-click on touchpad-sprint
	-- controllers (Vive): the run button IS the trackpad click, so re-clicking to
	-- toggle centres the pad and momentarily releases the stick - without this the
	-- click itself would trip the stick-centric cancel below. The bypass applies
	-- ONLY while the run input is held down (i.e. during the click itself), so
	-- once the pad is released, or whenever sticky sprint is off, the normal
	-- "must be pushing the stick to keep running" rules apply. This means non-Vive
	-- headsets (Index/Oculus, where the stick stays deflected during a click) are
	-- completely unaffected.
	if self._sprint_sticky and self._controller and self._controller:get_input_bool("run") then
		return true
	end

	return self._stick_move and old_can_run_directional(self) or false
end

-- Hand ourselves ('playerstate') to the states
local old_init = PlayerStandardVR.init
function PlayerStandardVR:init(unit)
	old_init(self, unit)

	-- Pass in our playerstate
	-- Always do this in case locomotion is later enabled.
	local controller = self._unit:base():controller()
	self._warp_state_machine = CoreFiniteStateMachine.FiniteStateMachine:new(WarpIdleState, "params", {
			state_data = self._state_data,
			unit = self._unit,
			input = self._movement_input,
			playerstate = self
	})

	self._warp_state_machine:set_debug(false)

	-- Non-time compensated movement, only counting locomotion
	-- See FPCameraPlayerBase
	self.__last_movement_xy = Vector3()

	-- Actual (post-physics) world-space movement between frames. The camera
	-- overshoot compensation measures this instead of the input-desired ghost
	-- delta: walking into a wall moves the ghost but not the player, and must
	-- not pull the camera.
	self.__last_actual_delta = Vector3()
	self.__last_actual_delta_z = 0

	local m_pos = self._ext_movement and self._ext_movement:m_pos()
	self.__last_actual_pos = mvector3.copy(m_pos or self._unit:position())

	-- Set when a jump/fall just ended, so the last airborne vertical delta
	-- (which is stale by one frame) can be dropped on touch-down.
	self.__last_in_air = false
end

-- The state instance persists across movement-state switches, so re-seed the
-- actual-movement origin whenever we (re-)enter the standard state. Without
-- this, a teleport that happened while another state was active (revive,
-- custody return, etc) would look like one giant movement delta and yank the
-- camera for a single frame.
Hooks:PostHook(PlayerStandardVR, "enter", "VRPlusResetActualMovementOrigin", function(self, state_data, enter_data)
	self.__last_actual_delta = self.__last_actual_delta or Vector3()
	self.__last_actual_pos = self.__last_actual_pos or Vector3()
	self.__last_actual_delta_z = 0
	self.__last_in_air = false

	local m_pos = self._ext_movement and self._ext_movement:m_pos()
	mvector3.set(self.__last_actual_pos, m_pos or self._unit:position())
end)

-- TODO remove when basegame rotation is confirmed to work
local function do_rotation(self, t, dt)
	local mode = VRPlusMod._data.turning_mode
	if mode == VRPlusMod.C.TURNING_OFF then return end

	local controller = self._unit:base():controller()
	local axis = controller:get_input_axis("touchpad_primary")
	local rot = VRManager:hmd_rotation():yaw() + self._camera_base_rot:yaw()

	if not axis then return end

	if mode == VRPlusMod.C.TURNING_SMOOTH then
		local deadzone = 0.75 -- TODO add option

		if math.abs(axis.x) > deadzone then
			-- Scale from nothing to 100% over the course of the active zone
			local amt = (axis.x > 0) and (axis.x - deadzone) or (axis.x + deadzone)
			amt = amt * 1/(1-deadzone)

			-- User-configurable rotation speed (degrees per second at full stick)
			local speed = VRPlusMod._data.smooth_rotation_speed or 180
			local delta = dt * speed * -amt
			self:set_base_rotation(Rotation(rot + delta, 0, 0))
		end
	else
		-- Snap turning
		local turn, nonturn = 0.75, 0.5
		local delay = VRPlusMod._data.rotation_delay or 0.15
		local rotation_amt = VRPlusMod._data.rotation_amount or 45

		-- Apply cooldown
		self.__snap_rotate_timer = math.max(-1, (self.__snap_rotate_timer or 0) - dt)

		-- Sometimes the player keeps rotating for some unknown reason
		-- controller = self._unit:base():controller()
		-- axis = controller:get_input_axis("touchpad_primary")
		-- rot = VRManager:hmd_rotation():yaw() + self._camera_base_rot:yaw()
		-- if not axis then return end

		if math.abs(axis.x) > turn and self.__snap_rotate_timer < 0 then
			self.__snap_rotate_timer = delay
			local amt = ((axis.x > 0) and 1 or -1) * rotation_amt

			self:set_base_rotation(Rotation(rot - amt, 0, 0))
		end
	end
end

-- Same as vanilla, but lacks the dedicated snap turn buttons on Oculus Touch
function PlayerStandardVR:_check_vr_actions(t, dt)
	local state = self._warp_state_machine:state()

	if state.update then
		state:update(t, dt)
	end

	self._warp_state_machine:transition()

	if self._warp_state_machine:state():warp() and not self._state_data.warping then
		self:_start_action_warp(t)
	end
end

local old_update = PlayerStandardVR.update
function PlayerStandardVR:update(t, dt)
	do_rotation(self, t, dt) -- Handle smooth/snap rotation

	old_update(self, t, dt)

	-- Reset all movement-related stuff so nothing blows up
	-- if the idle controller disappears (both hands are busy)
	-- Very important we do this after everything else is done updating.
	if VRPlusMod._data.movement_locomotion then -- TODO is this if necessary?
		self._move_dir = nil
		self._normal_move_dir = nil
	end

	-- Fix for movement speed not resetting after being downed or taking fall damage
	-- Check if we're actually on the ground but the game thinks we're in the air
	if self._state_data.in_air and self._unit:mover() and self._unit:mover():standing() then
		self._state_data.in_air = false
	end

	-- Also reset any slowdown that might have been applied
	if self._slowdown_mul then
		self._slowdown_mul = nil
		self._slowdown_run_prevent = nil
	end

	-- Fix for ducking state not being reset after fall damage
	-- If the game thinks we're ducking but our custom ducking state says we're not,
	-- end the ducking action to ensure the states are in sync
	-- Also check that we're in the standard state (not bleedout, etc.)
	if self._state_data.ducking and not self._state_data.__vrplus_duck and self._ext_movement and self._ext_movement:current_state_name() == "standard" then
		self:_end_action_ducking(t)
	end

end

-- Prevent _calculate_standard_variables from changing our velocity. Fixes #51
local mvec_throwaway_last_velocity = Vector3()
local old_calculate_standard_variables = PlayerStandard._calculate_standard_variables
function PlayerStandard:_calculate_standard_variables(t, dt)
	local real_last_velocity = self._last_velocity_xy
	self._last_velocity_xy = mvec_throwaway_last_velocity
	old_calculate_standard_variables(self, t, dt)
	self._last_velocity_xy = real_last_velocity
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
local mvec_actual_pos = Vector3()
local mvec_prev_ghost = Vector3()
local mvec_ghost_now = Vector3()
function PlayerStandardVR:_update_movement(t, dt)
	-- Actual (post-physics) movement between frames. _pos is refreshed from the
	-- unit position by _calculate_standard_variables before we get here, so a
	-- wall collision shows up as zero movement even though the ghost position
	-- (and thus the input-desired delta) advanced into the wall.
	mvector3.set(mvec_actual_pos, self._pos)
	mvector3.set(self.__last_actual_delta, mvec_actual_pos)
	mvector3.subtract(self.__last_actual_delta, self.__last_actual_pos)
	mvector3.set_z(self.__last_actual_delta, 0) -- XY only
	self.__last_actual_delta_z = mvec_actual_pos.z - self.__last_actual_pos.z
	mvector3.set(self.__last_actual_pos, mvec_actual_pos)

	-- When a jump/fall just ended, the last vertical delta is stale by one
	-- frame - the body has settled but the compensation still holds the last
	-- airborne step. Drop it the frame we touch down.
	if self.__last_in_air and not self._state_data.in_air then
		self.__last_actual_delta_z = 0
	end

	self.__last_in_air = self._state_data.in_air

	if not VRPlusMod._data.movement_locomotion then
		-- Vanilla movement (incl. warp): the actual movement tracked above is
		-- enough for the camera compensation. If nothing actually moved this
		-- frame (warp/vanilla-locomotion stop), clear the now-stale delta so
		-- the camera does not stay one step behind the units for a frame.
		mvector3.set(mvec_prev_ghost, self._ext_movement:ghost_position())
		old_update_movement(self, t, dt)
		mvector3.set(mvec_ghost_now, self._ext_movement:ghost_position())

		if mvector3.equal(mvec_ghost_now, mvec_prev_ghost) and not self._state_data.in_air then
			mvector3.set_zero(self.__last_actual_delta)
			self.__last_actual_delta_z = 0
		end

		return
	end

	local pos_new = mvec_pos_new
	local init_pos_ghost = mvec_pos_initial

	-- Use the unit position rather than ghost position, so that we collide against stuff
	mvector3.set(pos_new, self._pos)

	if self._state_data.on_zipline and self._state_data.zipline_data.position then
		local rot = Rotation()

		mrotation.set_look_at(rot, self._state_data.zipline_data.zipline_unit:zipline():current_direction(), math.UP)

		self._ext_camera:camera_unit():base()._output_data.rotation = rot

		mvector3.set(pos_new, self._state_data.zipline_data.position)
	else
		mvector3.set_z(pos_new, self._pos.z)

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

	self._ext_movement:set_ghost_position(pos_new)

	-- If we came to a stop this frame (no walk input while on the ground),
	-- the between-frame delta captured at the top of this function is stale
	-- by one frame - the units are already at their final position. Clear it
	-- so the camera does not sit one step behind (seen as a brief overshoot)
	-- right after the player stops moving.
	-- Also apply it after landing from a jump, as long as the player is not
	-- holding the stick: on the touch-down frame both axes must settle.
	-- A zipline is excluded: it keeps moving the player with no walk input.
	if mvector3.equal(pos_new, init_pos_ghost) and not self._state_data.in_air and not self._state_data.on_zipline then
		mvector3.set_zero(self.__last_actual_delta)
		self.__last_actual_delta_z = 0
	end

	-- Non-time compensated version we can use to
	-- fix up camera error (see FPCameraPlayerBase)
	--
	-- TODO set this even when locomotion is off, so that
	-- the hands no longer disappear (shift back a lot).
	--
	-- Note: this is the input-desired delta and may differ from the actual
	-- movement when colliding with a wall; the camera overshoot compensation
	-- uses the actual delta tracked at the top of this function instead.
	mvector3.set(self.__last_movement_xy, pos_new)
	mvector3.subtract(self.__last_movement_xy, init_pos_ghost)
	mvector3.set_z(self.__last_movement_xy, 0) -- XY only, this feeds _last_velocity_xy

	-- Time-compensated version
	mvector3.set(self._last_velocity_xy, self.__last_movement_xy)
	mvector3.divide(self._last_velocity_xy, dt)

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
end

Hooks:PreHook(PlayerStandard, "_check_action_interact", "VRPlusLockInteration", function(self, t, input)
	if not self._interact_params or not VRPlusMod._data.comfort.interact_lock then
		return
	end

	-- Prevent the interation from stopping
	input.btn_interact_release = false

	if not input.btn_interact_press then
		return
	end

	-- Prevent the player from interacting again
	-- IDK what would happen, but it wouldn't be any good.
	input.btn_interact_press = false

	local release_hand = input.btn_interact_left_press and PlayerHand.LEFT or PlayerHand.RIGHT
	if release_hand ~= self._interact_hand then
		-- Player let go with the hand they weren't interacting with
		return
	end

	-- Cancel the interaction
	input.btn_interact_release = true

	if self._interact_hand == PlayerHand.LEFT then
		input.btn_interact_left_release = true
	else
		input.btn_interact_right_release = true
	end
end)

-- The artificial crouch flag is stored on the shared _state_data table instead of
-- on the individual movement state object. Standard and carry are separate state
-- objects, so a per-state flag is "remembered" separately, which forced the player
-- to stand up when grabbing or releasing a bag. Storing it on _state_data keeps a
-- single persistent crouch state across state transitions. Fixes #3.
Hooks:PostHook(PlayerStandardVR, "_check_action_duck", "VRPlusSetDuckStatus", function(self, t, input)
	local mode = VRPlusMod._data.comfort.crouching
	local state_data = self._state_data
	local was_ducking = state_data.__vrplus_duck

	if mode == VRPlusMod.C.CROUCH_TOGGLE then
		if input.btn_duck_press then
			state_data.__vrplus_duck = not state_data.__vrplus_duck
		end
	elseif mode == VRPlusMod.C.CROUCH_HOLD then
		if input.btn_duck_release then
			state_data.__vrplus_duck = false
		elseif input.btn_duck_press then
			state_data.__vrplus_duck = true
		end
	else
		state_data.__vrplus_duck = false
	end

	-- Update the game's internal ducking state to match our custom state
	if was_ducking ~= state_data.__vrplus_duck then
		if state_data.__vrplus_duck then
			if not self._state_data.ducking then
				self:_start_action_ducking(t)
			end
		else
			if self._ext_movement and self._ext_movement:current_state_name() == "standard" and self._unit:mover() then
				-- Player explicitly pressed the button to stand up, so always make
				-- sure they actually do. Must not be gated on _state_data.ducking:
				-- after carrying/throwing a bag that flag can desync from the real
				-- body (mover left in duck while the flag already reads "standing"),
				-- leaving the player stuck crouched until a warp force-stands them.
				-- Matching warp/zipline, force the stand with skip_can_stand_check so
				-- _end_action_ducking restores the standing mover regardless.
				self:_end_action_ducking(t, true)
			end
		end
	end
end)

-- The carry movement state (PlayerCarryVR) extends the flat PlayerCarry state, not
-- PlayerStandardVR, so it never runs the artificial-crouch hook above. Carrying a
-- bag uses the vanilla duck handling (_state_data.ducking). Keep our shared
-- artificial crouch flag in sync with it, so crouching while holding a bag keeps the
-- same persistent crouch state once the bag is released. Fixes #3.
if PlayerCarryVR then
	Hooks:PostHook(PlayerCarryVR, "update", "VRPlusSyncCarryDuck", function(self, t, dt)
		if VRPlusMod._data.comfort.crouching ~= VRPlusMod.C.CROUCH_NONE and self._state_data then
			self._state_data.__vrplus_duck = self._state_data.ducking or false
		end
	end)

	-- Fix player being unable to stand up while carrying a bag when crouching
	Hooks:PreHook(PlayerCarryVR, "_check_action_duck", "VRPlusCarryDuckPreCapture", function(self, t, input)
		self._vrplus_carry_pre_ducking = (self._state_data and self._state_data.ducking) or false
	end)

	Hooks:PostHook(PlayerCarryVR, "_check_action_duck", "VRPlusForceCarryStand", function(self, t, input)
		local mode = VRPlusMod._data.comfort.crouching
		local pre_ducking = self._vrplus_carry_pre_ducking
		self._vrplus_carry_pre_ducking = nil

		if mode == VRPlusMod.C.CROUCH_NONE or not self._state_data or not self._unit:mover() then
			return
		end

		-- Did the player press the button to stand up, and is the body still ducked
		local want_stand
		if mode == VRPlusMod.C.CROUCH_TOGGLE then
			-- Toggle: a press while already ducking means "stand up".
			want_stand = input.btn_duck_press and pre_ducking
		else
			-- Hold: letting the button go means "stand up".
			want_stand = input.btn_duck_release
		end

		if want_stand and self._state_data.ducking then
			self:_end_action_ducking(t, true)
		end
	end)

	-- When grabbing a bag while artificial-crouched, the pickup (animation, hand
	-- carry setup) can stand the body up while our persistent __vrplus_duck intent
	-- stays true. That leaves the player visually crouched (HMD lowered) but the game
	-- treating them as standing (taller capsule, more crouch room), which then shows
	-- up as an instant "uncrouch" once they warp. Re-engage the body duck right at
	-- entry so the game logic matches the visual crouch from the moment of pickup.
	Hooks:PostHook(PlayerCarryVR, "enter", "VRPlusCarryEnterRestoreDuck", function(self, state_data, enter_data)
		if VRPlusMod._data.comfort.crouching == VRPlusMod.C.CROUCH_NONE then
			return
		end

		local sd = self._state_data or state_data

		-- Only force a duck if the artificial-crouch intent says crouch but the body
		-- was stood up. Leave standing players (intent off) alone.
		if sd and sd.__vrplus_duck and not sd.ducking and self._unit:mover() and not sd.warping then
			self:_start_action_ducking(managers.player:player_timer():time())
		end
	end)

	-- PlayerCarry's _start_action_warp also calls _interupt_action_ducking(t, true),
	-- which would stand the body and desync the crouch. The base PlayerCarry class has
	-- no _end_action_warp (warp completion happens silently in _upd_attention), so we
	-- can't restore after. Instead, prevent the uncrouch by replacing the method call.
	local original_carry_interrupt_duck = PlayerCarryVR._interupt_action_ducking
	function PlayerCarryVR:_interupt_action_ducking(t, skip_sync)
		if VRPlusMod._data.comfort.crouching == VRPlusMod.C.CROUCH_NONE then
			return original_carry_interrupt_duck(self, t, skip_sync)
		end

		local sd = self._state_data

		-- If called with skip_sync=true (warp's "force stand" call) while artificial-
		-- crouched, block it. Let normal ducking interrupts (button release, etc) through.
		if skip_sync and sd and sd.__vrplus_duck and sd.ducking then
			return
		end

		return original_carry_interrupt_duck(self, t, skip_sync)
	end

end
-- [[Warp restores the artificial crouch]]
-- _start_action_warp calls _interupt_action_ducking internally, which stands the
-- body up even when the player was using the artificial crouch. That clears the
-- body's ducking flag while our persistent __vrplus_duck intent stays true, so the
-- player ends up visually crouched (HMD lowered by __affect_vrobj_position) but the
-- game treats them as standing (taller capsule, larger crouch room). This is most
-- noticeable after grabbing a bag while crouched and then warping. Restore the body
-- duck when the warp finishes and the artificial crouch intent is still active.
Hooks:PostHook(PlayerStandardVR, "_end_action_warp", "VRPlusRestoreDuckAfterWarp", function(self, t)
	if VRPlusMod._data.comfort.crouching == VRPlusMod.C.CROUCH_NONE then
		return
	end

	local state_data = self._state_data

	-- Only re-crouch when the artificial crouch intent survived the warp but the body
	-- was stood up by it. Nop out when the player already stands (intent off) or the
	-- warp machinery hasn't fully settled yet.
	if state_data and state_data.__vrplus_duck and not state_data.ducking and self._unit:mover() and not state_data.warping and not state_data.warping_to_ladder then
		self:_start_action_ducking(t)
	end
end)


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

-- Since the 'jump' input isn't used by the vanilla game in VR, it's
-- action isn't disabled. As we use it for sprinting/jumping, make
-- sure the vanilla jumping logic doesn't fire (and lead to a crash).
--
-- In locomotion mode the jump is driven by WarpIdleState:update, so this stays a
-- no-op. In the vanilla movement modes (Dash / Direct / Dash+Direct) with the
-- mod's locomotion disabled, WarpIdleState never runs - so trigger a real jump
-- from the bound 'jump' input here instead, re-using the locomotion jump logic.

-- True when the vanilla VR movement setting includes a direct-walking component
-- (Dash+Direct or Direct-only). Pure Dash ('warp') is teleport-only: there is no
-- joystick movement to carry a jump, so the jump button stays disabled there.
function PlayerStandardVR:_vrplus_has_direct_movement()
	local movement_type = managers.vr and managers.vr:get_setting("movement_type")
	return movement_type ~= "warp" and movement_type ~= nil
end

function PlayerStandardVR:_check_action_jump(t, input)
	if VRPlusMod._data.movement_locomotion then
		return false
	end

	-- Jump is opt-in via the "Enable Jump Button" motion controller option.
	if VRPlusMod._data.jump_enabled == false then
		return false
	end

	-- Pure Dash (teleport-only) vanilla movement has no direct walking, so the
	-- button jump is disabled there and only works with a direct movement mode.
	if not self:_vrplus_has_direct_movement() then
		return false
	end

	if not self.vrplus_trigger_jump then
		return false
	end

	local jump_pressed = self._controller and self._controller:get_input_bool("jump")
	if jump_pressed then
		-- Same "must be near the center of the stick/touchpad" restriction the
		-- locomotion mode applies when the jump button is the stick click.
		if self.vrplus_jump_requires_center_click and self.vrplus_jump_requires_center_click() then
			local axis = self._controller:get_input_axis("touchpad_primary")
			if axis and (math.abs(axis.x) > 0.2 or math.abs(axis.y) > 0.2) then
				jump_pressed = false
			end
		end
	end

	if jump_pressed then
		-- The jump logic (ps_trigger_jump / orig_start_action_jump) keys off
		-- _move_dir, which in locomotion mode is set by WarpIdleState's
		-- custom_move_direction. In the vanilla movement modes it stays nil, so
		-- the jump would get no horizontal velocity and end up using the walk
		-- impulse even mid-sprint. Seed it from the current direct-movement axis
		-- so the horizontal jump velocity matches the player's actual movement,
		-- then restore it.
		local prev_move_dir = self._move_dir
		local prev_normal_move_dir = self._normal_move_dir
		local move_input = self._movement_input
		local input_state = move_input and move_input:state()
		local move_axis = input_state and input_state.move_axis
		if move_axis then
			self._move_dir = mvector3.copy(move_axis)
		end

		-- Find out if the vanilla movement is sprinting so the correct (run vs
		-- walk) jump velocity is applied. The vanilla Dash+Direct mode drives
		-- sprinting through the run input latch on the movement input (state().run
		-- - true while the player is sprinting across the floor), plus the
		-- internal _running/set_running state. Checking both covers the case where
		-- one of them is momentarily stale: e.g. sticky-sprint latched _running but
		-- the vanilla run latch was cleared, or the vanilla latch is live but the
		-- internal _running hadn't been committed this frame yet.
		local is_vanilla_sprinting = self._running or (input_state and input_state.run)

		-- vrplus_trigger_jump re-uses the locomotion jump logic; passing the explicit
		-- sprint state lets it pick the run jump velocity (and stamina drain)
		-- instead of its internal _start_running_t / stamina heuristics, which
		-- don't line up with the vanilla movement running state.
		self:vrplus_trigger_jump(t, is_vanilla_sprinting and true or false)

		self._move_dir = prev_move_dir
		self._normal_move_dir = prev_normal_move_dir
	end

	return false
end

-- Fix weapons breaking (minigun firerate in automatic, won't fire in
-- semifire mode) after being tazed.
--
-- This is caused when the player fires on the same frame they are tazed.
-- When they stop being tazed, _shooting is set to false but _shooting_weapons
-- isn't necessaraly cleared.
--
-- For _shooting_weapons to be emptied, _shooting must be true - we're getting
-- stuck in a state where _shooting is false and _shooting_weapons is not empty.

Hooks:PreHook(PlayerStandardVR, "_check_fire_per_weapon", "VRPlusFixWeaponFireRate", function(self)
	if not self._shooting and self._shooting_weapons and next(self._shooting_weapons) then
		self._shooting_weapons = {}
	end
end)
