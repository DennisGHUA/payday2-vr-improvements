--[[
	Set up the default values, both global and per-HMD
	
	First set up the defaults table. Then overwrite stuff depending on the HMD in use.
]]

local default_data = {
	deadzone = 10,
	sprint_time = 0.25,
	turning_mode = VRPlusMod.C.TURNING_SNAP,
	sprint_mode = VRPlusMod.C.SPRINT_STICKY,
	movement_controller_direction = false,
	movement_locomotion = true,
	movement_smoothing = true,
	teleport_on_release = false,
	rotation_delay = 0.15,
	rotation_amount = 45,
	smooth_rotation_speed = 180,
	
	-- Controller type - auto-detected by default
	controller_type = nil,
	
	-- Button mappings for all controllers
	-- Face buttons sit on a fixed controller: A/B right, X/Y left
	button_jump = VRPlusMod.C.BUTTON_B,
	button_crouch = VRPlusMod.C.BUTTON_A,
	button_pause = VRPlusMod.C.BUTTON_Y,
	-- Left/right turn the view, so gadget and fire mode go on up/down
	button_gadget = VRPlusMod.C.BUTTON_TOUCHPAD_UP_DOMINANT,
	button_firemode = VRPlusMod.C.BUTTON_TOUCHPAD_DOWN_DOMINANT,

	-- Camera fading parameters
	cam_fade_distance = 0,
	cam_reset_percent = 95,
	cam_reset_timer = 0.25,

	cam_redout_enable = false,
	cam_redout_hp_start = 15,
	cam_redout_fade_max = 50,

	comfort = {
		max_movement_speed_enable = false,
		max_movement_speed = 400,
		interact_mode = VRPlusMod.C.INTERACT_GRIP,
		interact_lock = false,
		crouching = VRPlusMod.C.CROUCH_TOGGLE,
		crouch_scale = 50,
		nil
	},

	hud = {
		watch_health_wheel = true,
		belt_radio = false,
		tablet_heist_info = true,
	},

	tweaks = {
		laser_hue = 1/10,
		laser_disco = true,
		endscreen_speedup = 5,
		force_quality_enable = false,
		force_quality = 4,
		weapon_melee = VRPlusMod.C.WEAPON_MELEE_LOUD,
	}
}

local defaults_rift = {
	controller_type = VRPlusMod.C.CONTROLLER_TOUCH,
	nil
}

local defaults_index = {
	controller_type = VRPlusMod.C.CONTROLLER_KNUCKLES,
	nil
}

local defaults_vive = {
	sprint_time = 0.15,
	controller_type = VRPlusMod.C.CONTROLLER_VIVE,

	-- Vive wands have no A/B/X/Y buttons, so use the touchpad/menu layout.
	button_jump = VRPlusMod.C.BUTTON_TOUCHPAD_CENTER_DOMINANT,
	button_crouch = VRPlusMod.C.BUTTON_TOUCHPAD_MENU_OFF,
	button_pause = VRPlusMod.C.BUTTON_TOUCHPAD_MENU_DOMINANT,

	comfort = {
		interact_mode = VRPlusMod.C.INTERACT_BOTH,
	},
	
	nil
}

local defaults_frame = {
	controller_type = VRPlusMod.C.CONTROLLER_FRAME,
	nil
}

-- Add other HMDs here

local function copy_defaults(src, hmd_src, dest)
	for name, val in pairs(src) do
		local override = hmd_src and hmd_src[name]
		if type(val) == "table" then
			local dest_t = {}
			copy_defaults(val, override, dest_t)
			dest[name] = dest_t
		else
			dest[name] = override or val
		end
	end
end

function VRPlusMod:_get_defaults(hmd_type)
	local brand = blt_vr and blt_vr.gethmdbrand() or "generic"
	if not hmd_type then
		hmd_type = ({
			["Oculus"] = "Rift",
			["Meta"] = "Rift",
			["Index"] = "Index",
			["HTC"] = "Vive",
			["Valve"] = "Frame"  -- Steam Frame detection
		})[brand]
	end
	
	local usable_hmd_type = hmd_type or "generic"

	if blt_vr and not hmd_type then
		log("Unknown HMD Brand '" .. brand .. "' - please submit an issue to help set up defaults values for this.")
	end

	local hmd_defaults = ({
		["generic"] = nil,
		["Rift"] = defaults_rift,
		["Index"] = defaults_index,
		["Vive"] = defaults_vive,
		["Frame"] = defaults_frame
	})[usable_hmd_type]

	local output = {
		defaults_hmd = usable_hmd_type
	}
	
	copy_defaults(default_data, hmd_defaults, output)

	return output, hmd_type
end

