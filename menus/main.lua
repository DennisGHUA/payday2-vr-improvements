
--[[
	We setup the global table for our mod, along with some path variables, and a data table.
	We cache the ModPath directory, so that when our hooks are called, we aren't using the ModPath from a
		different mod.
]]
_G.VRPlusMod = _G.VRPlusMod or {}

-- Constants
VRPlusMod.C = {
	TURNING_OFF = 1,
	TURNING_SMOOTH = 2,
	TURNING_SNAP = 3,

	SPRINT_OFF = 1,
	SPRINT_STICKY = 2,
	SPRINT_HOLD = 3,

	nil
}

VRPlusMod._path = ModPath
VRPlusMod._data_path = SavePath .. "vr_improvements.conf"
VRPlusMod._data = {}
VRPlusMod._default_data = {
	deadzone = 10,
	sprint_time = 0.25,
	turning_mode = VRPlusMod.C.TURNING_OFF,
	sprint_mode = VRPlusMod.C.SPRINT_STICKY,
	movement_controller_direction = true,
	movement_locomotion = true,

	-- Camera fading parameters
	cam_fade_distance = 2,
	cam_reset_percent = 95,
	cam_reset_timer = 0.25,

	cam_redout_enable = false,
	cam_redout_hp_start = 15,
	cam_redout_fade_max = 50,

	comfort = {
		max_movement_speed_enable = false,
		max_movement_speed = 400
	},

	hud = {
		watch_health_wheel = true
	}
}

--[[
	A simple save function that json encodes our _data table and saves it to a file.
]]
function VRPlusMod:Save()
	local file = io.open( self._data_path, "w+" )
	if file then
		file:write( json.encode( self._data ) )
		file:close()
	end
end

local function load_defaults(defaults, target)
	for name, default in pairs(defaults) do
		-- Make sure to specificly say 'nil', so values set to false work
		if type(default) == "table" then
			local subtarget = target[name] or {}
			target[name] = subtarget
			load_defaults(default, target[name])
		elseif target[name] == nil then
			target[name] = default
		end
	end
end

--[[
	A simple load function that decodes the saved json _data table if it exists.
]]
function VRPlusMod:Load()
	local file = io.open( self._data_path, "r" )
	if file then
		self._data = json.decode( file:read("*all") )
		file:close()
	end
	
	-- Copy in any new properties
	load_defaults(self._default_data, self._data)
end

--[[
	Load our previously saved data from our save file.
]]
VRPlusMod:Load()

--[[
	Load our localization keys for our menu, and menu items.
]]
Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_VRPlusMod", function( loc )
	-- Load english as the fallback for any missing keys
	-- If a non-english language is in use, it will overwrite these keys
	loc:load_localization_file( VRPlusMod._path .. "lang/en.lang")

	for key, code in pairs({
		russian = "ru"
	}) do
		if Idstring(key) and Idstring(key):key() == SystemInfo:language():key() then
			loc:load_localization_file(VRPlusMod._path .. "lang/" .. code .. ".lang")
		end
	end
end)

--[[
	Setup our menu callbacks, load our saved data, and build the menu from our json file.
]]
Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_VRPlusMod", function( menu_manager )
	local data = VRPlusMod._data

	local function add_inputs(scope, checkboxes, names)
		for _, name in ipairs(names) do
			MenuCallbackHandler["vrplus_" .. name] = function(self, item)
				if checkboxes then
					scope[name] = (item:value() == "on" and true or false)
				else
					scope[name] = item:value()
				end
				VRPlusMod:Save()
			end
		end
	end

	-- Checkboxes
	add_inputs(data, true, {
		"movement_controller_direction",
		"movement_locomotion",
		"cam_redout_enable"
	})

	-- Sliders and multiselectors
	add_inputs(data, false, {
		"deadzone",
		"sprint_time",
		"sprint_time",
		"turning_mode",

		"cam_fade_distance",
		"cam_reset_percent",
		"cam_reset_timer",

		"cam_redout_hp_start",
		"cam_redout_fade_max",

		"sprint_mode"
	})

	-- Comfort options
	add_inputs(data.comfort, true, {
		"max_movement_speed_enable"
	})
	add_inputs(data.comfort, false, {
		"max_movement_speed"
	})

	-- HUD options
	add_inputs(data.hud, true, {
		"watch_health_wheel"
	})

	--[[
		Load our menu json file and pass it to our MenuHelper so that it can build our in-game menu for us.
		The second option used to be for keybinds, however that seems to not be implemented on BLT2.
		We also pass our data table as the third argument so that our saved values can be loaded from it.
	]]
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/mainmenu.json", nil, data )
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/camera.json", nil, data )
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/controllers.json", nil, data )
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/comfort.json", nil, data.comfort )
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/hud.json", nil, data.hud )

end)
