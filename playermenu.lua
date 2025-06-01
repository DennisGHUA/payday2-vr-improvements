--[[
	HUDManagerVR

	Make the laser pointer in the menu have a configurable colour, with a disco mode
	Also implement rotation in the main menu
--]]

-- From https://gist.github.com/GigsD4X/8513963
local function HSVToRGB( hue, saturation, value )
	-- Returns the RGB equivalent of the given HSV-defined color
	-- (adapted from some code found around the web)

	-- If it's achromatic, just return the value
	if saturation == 0 then
		return value
	end

	-- Get the hue sector
	local hue_sector = math.floor( hue / 60 )
	local hue_sector_offset = ( hue / 60 ) - hue_sector

	if hue_sector > 5 then hue_sector = 0 end

	local p = value * ( 1 - saturation );
	local q = value * ( 1 - saturation * hue_sector_offset )
	local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) )

	if hue_sector == 0 then
		return value, t, p
	elseif hue_sector == 1 then
		return q, value, p
	elseif hue_sector == 2 then
		return p, value, t
	elseif hue_sector == 3 then
		return p, q, value
	elseif hue_sector == 4 then
		return t, p, value
	elseif hue_sector == 5 then
		return value, p, q
	end
end

Hooks:PreHook(PlayerMenu, "update", "VRPlusUpdateLaserColour", function(self, t, dt)
	if not self._is_start_menu or self.__laser_is_updated or not VRPlusMod or not VRPlusMod._data or not VRPlusMod._data.tweaks then
		return
	end

	local hue = VRPlusMod._data.tweaks.laser_hue or 0
	if VRPlusMod._data.tweaks.laser_disco then
		local speedup = 2 -- maximum of once every 0.5 seconds
		local delta = hue * hue * speedup * dt -- square hue to get a nice logrhytmic timescale
		local last = self.__laser_last_hue or 0
		hue = (last + delta) % 1
		self.__laser_last_hue = hue
	end
	-- don't constantly update if we don't need to
	self.__laser_is_updated = not VRPlusMod._data.tweaks.laser_disco

	local r, g, b = HSVToRGB(hue * 360, 1, 1)
	local colour = Color(0.15, r, g, b)
	self._brush_laser:set_color(colour)
	self._brush_laser_dot:set_color(colour)
	
	-- Apply rotation in main menu if enabled
	if VRPlusMod._data.turning_mode ~= VRPlusMod.C.TURNING_OFF then
		self:handle_menu_rotation(t, dt)
	end
end)

-- Add rotation handling for the main menu
function PlayerMenu:handle_menu_rotation(t, dt)
	-- Wrap everything in pcall for stability
	local success, error_msg = pcall(function()
		if not VRPlusMod or not VRPlusMod._data or not VRPlusMod._data.turning_mode then return end
		
		local mode = VRPlusMod._data.turning_mode
		local controller = managers.controller and managers.controller:get_vr_controller()
		if not controller then return end
		
		local axis = controller:get_input_axis("touchpad_primary")
		if not axis then return end
		
		local baseRot = self._camera_base_rot or Rotation()
		local rot = VRManager and VRManager:hmd_rotation() and VRManager:hmd_rotation():yaw() + baseRot:yaw() or 0

		-- Check if we need to require a button press for rotation
		local requires_press = VRPlusMod._data.rotation_requires_press
		local button_pressed = not requires_press
				if requires_press then
			-- Check for both directional presses and the generic trackpad button
			button_pressed = button_pressed or 
				controller:get_input_bool("d_left_r") or 
				controller:get_input_bool("d_right_r") or 
				controller:get_input_bool("d_left_l") or 
				controller:get_input_bool("d_right_l") or
				controller:get_input_bool("trackpad_button_r") or
				controller:get_input_bool("trackpad_button_l")
		end
		
		if not button_pressed then
			return
		end
		
		if mode == VRPlusMod.C.TURNING_SMOOTH then
			local deadzone = 0.75
			if math.abs(axis.x) > deadzone then
				-- Scale from nothing to 100% over the course of the active zone
				local amt = (axis.x > 0) and (axis.x - deadzone) or (axis.x + deadzone)
				amt = amt * 1/(1-deadzone)

				-- One full revolution per second on maxed stick
				local delta = dt * 360 / 2 * -amt
				if managers.player and managers.player._menu_unit and alive(managers.player._menu_unit) then
					local menu_unit = managers.player._menu_unit
					if menu_unit.set_base_rotation then
						-- Wrap in pcall for safety
						pcall(function()
							menu_unit:set_base_rotation(Rotation(rot + delta, 0, 0))
						end)
					end
				end
			end
		else		-- Snap turning
			local turn, nonturn = 0.75, 0.5
			local delay = VRPlusMod._data.rotation_delay or 0.50
			-- Get rotation amount and enforce step of 5 degrees
			local raw_amt = VRPlusMod._data.rotation_amount or 45
			local rotation_amt = math.floor((raw_amt + 2.5) / 5) * 5 -- Round to nearest increment of 5
			
			-- Store the last rotation time in the player menu object
			self.__snap_rotate_timer = math.max(-1, (self.__snap_rotate_timer or 0) - dt)

			if math.abs(axis.x) > turn and self.__snap_rotate_timer < 0 then
				self.__snap_rotate_timer = delay
				local amt = ((axis.x > 0) and 1 or -1) * rotation_amt

				if managers.player and managers.player._menu_unit and alive(managers.player._menu_unit) then
					local menu_unit = managers.player._menu_unit
					if menu_unit.set_base_rotation then
						-- Wrap in pcall for safety
						pcall(function()
							menu_unit:set_base_rotation(Rotation(rot - amt, 0, 0))
						end)
					end
				end
			end
		end
	end) -- End of pcall
	
	-- If an error occurred, we'll catch it here but won't crash the game
	if not success then
		-- We could log the error here if we had a logging system
		-- But for now we'll just silently fail
	end
end
