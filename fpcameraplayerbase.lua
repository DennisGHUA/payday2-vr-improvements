
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
