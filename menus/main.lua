
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
	TURNING_SNAP = 3
}

VRPlusMod._path = ModPath
VRPlusMod._data_path = SavePath .. "vr_improvements.conf"
VRPlusMod._data = {}
VRPlusMod._default_data = {
	rift_stickysprint = true,
	deadzone = 10,
	sprint_time = 0.25,
	turning_mode = VRPlusMod.C.TURNING_OFF,
	movement_controller_direction = true,

	-- Camera fading parameters
	cam_fade_distance = 2,
	cam_reset_percent = 95,
	cam_reset_timer = 0.25
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
	for name, default in pairs(VRPlusMod._default_data) do
		-- Make sure to specificly say 'nil', so values set to false work
		if self._data[name] == nil then
			self._data[name] = default
		end
	end
end

--[[
	Load our localization keys for our menu, and menu items.
]]
Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_VRPlusMod", function( loc )
	loc:load_localization_file( VRPlusMod._path .. "lang/en.lang")
end)

--[[
	Setup our menu callbacks, load our saved data, and build the menu from our json file.
]]
Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_VRPlusMod", function( menu_manager )

	-- Checkboxes
	for _, name in ipairs({
		"rift_stickysprint",
		"movement_controller_direction"
	}) do
		MenuCallbackHandler["vrplus_" .. name] = function(self, item)
			VRPlusMod._data[name] = (item:value() == "on" and true or false)
			VRPlusMod:Save()
		end
	end

	-- Sliders and multiselectors
	for _, name in ipairs({
		"deadzone",
		"sprint_time",
		"sprint_time",
		"turning_mode",

		"cam_fade_distance",
		"cam_reset_percent",
		"cam_reset_timer"
	}) do
		MenuCallbackHandler["vrplus_" .. name] = function(self, item)
			VRPlusMod._data[name] = item:value()
			VRPlusMod:Save()
		end
	end

	--[[
		Load our previously saved data from our save file.
	]]
	VRPlusMod:Load()

	--[[
		Load our menu json file and pass it to our MenuHelper so that it can build our in-game menu for us.
		We pass our parent mod table as the second argument so that any keybind functions can be found and called
			as necessary.
		We also pass our data table as the third argument so that our saved values can be loaded from it.
	]]
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/mainmenu.json", nil, VRPlusMod._data )
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/camera.json", nil, VRPlusMod._data )
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/controllers.json", nil, VRPlusMod._data )

end)
