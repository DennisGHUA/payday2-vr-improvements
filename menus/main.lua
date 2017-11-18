
--[[
	We setup the global table for our mod, along with some path variables, and a data table.
	We cache the ModPath directory, so that when our hooks are called, we aren't using the ModPath from a
		different mod.
]]
_G.VRPlusMod = _G.VRPlusMod or {}
VRPlusMod._path = ModPath
VRPlusMod._data_path = SavePath .. "vr_improvements.conf"
VRPlusMod._data = {}
VRPlusMod._default_data = {
	rift_stickysprint = true,
	deadzone = 10,
	sprint_time = 0.25
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
		self._data[name] = self._data[name] or default
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

	MenuCallbackHandler.vrplus_rift_stickysprint = function(self, item)
		VRPlusMod._data.rift_stickysprint = (item:value() == "on" and true or false)
		VRPlusMod:Save()
	end
	
	MenuCallbackHandler.vrplus_deadzone = function(self, item)
		VRPlusMod._data.deadzone = item:value()
		VRPlusMod:Save()
	end

	MenuCallbackHandler.vrplus_sprint_time = function(self, item)
		VRPlusMod._data.sprint_time = item:value()
		VRPlusMod:Save()
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

end)
