local mvec_temp1 = Vector3()
local mvec_temp2 = Vector3()
local mvec_temp3 = Vector3()

function FPCameraPlayerBase:_update_fadeout(hmd_position, ghost_position, t, dt)
	local fadeout_data = self._fadeout

	if FPCameraPlayerBase.NO_FADEOUT or self._parent_movement_ext:warping() or self._parent_movement_ext:current_state_name() == "driving" then
		fadeout_data.value = 0
		fadeout_data.effect.color.alpha = 0

		return
	end

	local distance_to_hmd = mvector3.distance(ghost_position:with_z(0), hmd_position:with_z(0))
	local rotation = self._output_data.rotation
	local dir = mvec_temp1

	mvector3.set(dir, math.Y)

	dir = dir:rotate_with(rotation)

	mvector3.multiply(dir, 20)

	local p_behind = mvec_temp2

	mvector3.set(p_behind, ghost_position)
	mvector3.subtract(p_behind, dir)

	local p_ahead = mvec_temp3

	mvector3.set(p_ahead, ghost_position)
	mvector3.add(p_ahead, dir)

	local ghost_max_th = 50
	local fade_distance = VRPlusMod._data.cam_fade_distance -- 13
	local distance_to_obstacle = fade_distance
	local fadeout = 0
	local ray = self._parent_unit:raycast("ray", p_behind, p_ahead, "slot_mask", fadeout_data.slotmask, "ray_type", "body mover", "sphere_cast_radius", 10, "bundle", 5)

	if ray then
		local obstacle_min_th = 7
		local distance = mvector3.distance(ghost_position, ray.position)

		if distance <= obstacle_min_th then
			distance_to_obstacle = 0
		elseif distance < obstacle_min_th + fade_distance then
			distance_to_obstacle = distance - obstacle_min_th
		end
	end

	if distance_to_hmd > 10 and distance_to_obstacle > 0 then
		local obstacle_min_th = 5.5
		local p_ahead = mvec_temp1

		mvector3.set(p_ahead, ghost_position)
		mvector3.subtract(p_ahead, hmd_position)
		mvector3.normalize(p_ahead)
		mvector3.multiply(p_ahead, 60)
		mvector3.add(p_ahead, ghost_position)

		local ray = self._parent_unit:raycast("ray", hmd_position, p_ahead, "slot_mask", fadeout_data.slotmask, "ray_type", "body mover", "sphere_cast_radius", 10, "bundle", 5)

		if ray then
			local d1 = mvector3.distance(hmd_position, ray.position)
			local d2 = mvector3.distance(hmd_position, ghost_position)
			local d = d1 - d2

			if d1 < d2 or d <= obstacle_min_th then
				distance_to_obstacle = 0
			elseif d < obstacle_min_th + fade_distance then
				distance_to_obstacle = d - obstacle_min_th
			end
		end
	end

	fadeout = 1 - distance_to_obstacle / fade_distance

	if ghost_max_th < distance_to_hmd then
		fadeout = math.max((distance_to_hmd - ghost_max_th) / fade_distance, fadeout)
	end

	fadeout = math.clamp(fadeout, 0, 1)

	if fadeout_data.value < fadeout then
		fadeout_data.value = math.step(fadeout_data.value, fadeout, fadeout < 1 and dt * 3 or dt * 10)
		fadeout_data.fadein_speed = 0
	elseif fadeout < fadeout_data.value then
		fadeout_data.value = math.step(fadeout_data.value, fadeout, dt * fadeout_data.fadein_speed)
		fadeout_data.fadein_speed = math.min(fadeout_data.fadein_speed + dt * 1, 0.7)
	end

	local v = fadeout_data.value
	fadeout_data.effect.color.alpha = v * v * (3 - 2 * v)

	if fadeout > (VRPlusMod._data.cam_reset_percent / 100) then -- 0.95
		self._ghost_reset_timer_t = self._ghost_reset_timer_t + dt
	else
		self._ghost_reset_timer_t = 0
	end

	if self._ghost_reset_timer_t > VRPlusMod._data.cam_reset_timer then -- 1.5
		self._parent_movement_ext:reset_ghost_position()

		self._ghost_reset_timer_t = 0
	end

end
