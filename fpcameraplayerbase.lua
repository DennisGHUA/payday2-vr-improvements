
-- This file is loaded in the flat game AFAIK, and
-- makes changes that would probably crash the game
-- when run like that.
if not _G.IS_VR then return end

Hooks:PostHook(FPCameraPlayerBase, "init", "VRPlusSetRedoutTable", function(self)
	self.__redout = {
		effect = {
			blend_mode = "normal",
			fade_out = 0,
			play_paused = true,
			fade_in = 0,
			color = Color(0, 255, 0, 0),
			timer = TimerManager:main()
		},
		slotmask = managers.slot:get_mask("statics")
	}

	-- FIXME this is a ugly hack.
	-- Used by MenuManagerVR to hide redout on opening a menu
	-- AFAIK only one VR camera is created, so this is... safe-ish.
	FPCameraPlayerBase.__redout = self.__redout
end)

Hooks:PostHook(FPCameraPlayerBase, "set_parent_unit", "VRPlusInitRedout", function(self)
	self.__redout.effect_id = self.__redout.effect_id or managers.overlay_effect:play_effect(self.__redout.effect)
end)

Hooks:PostHook(FPCameraPlayerBase, "_update_fadeout", "VRPlusRedoutEffect", function(self, hmd_position, ghost_position, t, dt)

	if VRPlusMod._data.cam_redout_enable then
		local player = managers.player:player_unit()
		if alive(player) then

			local health = player:character_damage():health_ratio()

			-- Check if the player is downed or in custody and set alpha to zero
			local character_damage = player:character_damage()
			if character_damage then
				-- Check if the player is downed or in custody and set alpha to zero
				if health <= 0 or character_damage:arrested() then
					self.__redout.effect.color.alpha = 0
					return
				end
			end


			local opacity_max = VRPlusMod._data.cam_redout_fade_max / 100
			local ratio_start = VRPlusMod._data.cam_redout_hp_start / 100

			if opacity_max > 0 and ratio_start > 0 then
				self.__redout.effect.color.alpha = (1 - math.min(1, health / ratio_start)) * opacity_max
			end
		else
			-- Disable redout is player is not alive()
			self.__redout.effect.color.alpha = 0
		end
	else
		-- Disable redout if this settings is disabled
		self.__redout.effect.color.alpha = 0
	end

end)

-- Remove the overshot effect - running moves your hands, weapons, belt and
-- the rest of the player-relative presentation backwards.
--
-- Diesel engine units (hands, weapons, belt, floating HUD, etc) only apply the
-- position written with set_position() on the next frame - not the one being
-- rendered. The camera is not affected by this and reads the ghost position
-- directly, so you'll always be looking at the position everything else should
-- have caught up to, but hasn't.
--
-- To compensate, subtract the actual (post-physics) movement between the
-- previous frame and this one (which all the other objects are still stuck
-- at). The actual movement delta is tracked by PlayerStandardVR; using it
-- (rather than the input-desired ghost delta) means walking into a wall
-- moves the ghost position but not the player, and does not pull the camera.
-- Both the horizontal (locomotion/warp) and vertical (jumps, falls) movement
-- is covered.
--
-- Restored for PAYDAY 2 Update 247: the Diesel 3.0 rewrite dropped this from
-- the base game, so this class of lag regressed for every object that is
-- attached to the player's VR presentation.
--
-- Note this only affects movement from locomotion/warp/jump - anything else
-- that moves your camera (physical head motion, turning) is not affected, so
-- as not to increase input lag.
local mvec_overshot_delta = Vector3()

Hooks:PostHook(FPCameraPlayerBase, "_update_movement", "VRPlusRemoveOvershot", function(self)
	local playerstate = self._parent_movement_ext and self._parent_movement_ext:current_state()
	local delta_xy = playerstate and playerstate.__last_actual_delta

	-- In case we're in a state that has never done a position update
	if delta_xy then
		mvector3.set(mvec_overshot_delta, delta_xy)
		mvector3.set_z(mvec_overshot_delta, playerstate.__last_actual_delta_z or 0)
		mvector3.subtract(self._output_data.position, mvec_overshot_delta)
	end
end)
