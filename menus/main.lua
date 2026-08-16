-- If you want to use the korean language patch, enable this
local LANG_KOREAN = false

--[[
	We setup the global table for our mod, along with some path variables, and a data table.
	We cache the ModPath directory, so that when our hooks are called, we aren't using the ModPath from a
		different mod.
]]
_G.VRPlusMod = _G.VRPlusMod or {}

-- Conflict warning timer (debounced, shown immediately after selection)
VRPlusMod._conflict_timer = nil

-- Constants
VRPlusMod.C = {
	TURNING_OFF = 1,
	TURNING_SMOOTH = 2,
	TURNING_SNAP = 3,

	SPRINT_OFF = 1,
	SPRINT_STICKY = 2,
	SPRINT_HOLD = 3,
	SPRINT_HOLD_OUTER = 3, -- Disabled was 4 will be replaced with SPRINT_HOLD, jump logic is now separated

	INTERACT_GRIP = 1,
	INTERACT_BOTH = 2,
	INTERACT_TRIGGER = 3,

	CROUCH_NONE = 1,
	CROUCH_TOGGLE = 2,
	CROUCH_HOLD = 3,

	WEAPON_MELEE_ENABLED = 1,
	WEAPON_MELEE_LOUD = 2,
	WEAPON_MELEE_DISABLED = 3,

	-- Controller types
	CONTROLLER_VIVE = 1,      -- HTC Vive wands (touchpad-based)
	CONTROLLER_TOUCH = 2,     -- Oculus Touch (button-based: A/B/X/Y)
	CONTROLLER_KNUCKLES = 3,  -- Valve Index Knuckles (button-based: A/B)
	CONTROLLER_FRAME = 4,     -- Steam Frame controllers (button-based: A/B, expected similar to Knuckles)

	-- Button mapping options (for button-based controllers)
	BUTTON_A = 1,
	BUTTON_B = 2,
	BUTTON_X = 3,
	BUTTON_Y = 4,
	BUTTON_MENU = 5,
	BUTTON_DPAD_UP = 6,
	BUTTON_DPAD_DOWN = 7,
	BUTTON_DPAD_LEFT = 8,
	BUTTON_DPAD_RIGHT = 9,

	nil
}

-- Load the default options
dofile(ModPath .. "menus/defaults.lua")

VRPlusMod._path = ModPath
VRPlusMod._data_path = SavePath .. "vr_improvements.conf"
VRPlusMod._data = {}
VRPlusMod._menu_ids = {}

--[[
	Recursively pretty-prints a Lua table as JSON with indentation.
	Used so the save file is human-readable instead of one long line.
]]
local function json_encode_pretty(value, indent)
	indent = indent or 0
	local pad = string.rep( "\t", indent )
	local pad_inner = string.rep( "\t", indent + 1 )

	local value_type = type(value)

	if value_type == "table" then
		local is_array = true
		local count = 0
		for k in pairs(value) do
			count = count + 1
			if type(k) ~= "number" then
				is_array = false
			end
		end
		if is_array then
			for i = 1, count do
				if value[i] == nil then
					is_array = false
					break
				end
			end
		end

		if count == 0 then
			return is_array and "[]" or "{}"
		end

		local parts = {}
		if is_array then
			for i = 1, count do
				table.insert( parts, pad_inner .. json_encode_pretty( value[i], indent + 1 ) )
			end
			return "[\n" .. table.concat( parts, ",\n" ) .. "\n" .. pad .. "]"
		else
			local keys = {}
			for k in pairs(value) do
				table.insert( keys, k )
			end
			table.sort( keys, function(a, b) return tostring(a) < tostring(b) end )

			for _, k in ipairs(keys) do
				local key_str = string.format( "%q", tostring(k) )
				table.insert( parts, pad_inner .. key_str .. ": " .. json_encode_pretty( value[k], indent + 1 ) )
			end
			return "{\n" .. table.concat( parts, ",\n" ) .. "\n" .. pad .. "}"
		end

	elseif value_type == "string" then
		return string.format( "%q", value )
	elseif value_type == "number" or value_type == "boolean" then
		return tostring( value )
	else
		return "null"
	end
end

--[[
	A simple save function that json encodes our _data table and saves it to a file,
	pretty-printed for readability.
]]
function VRPlusMod:Save()
	local save_data = {}
	for k, v in pairs(self._data) do
		save_data[k] = v
	end
	local file = io.open( self._data_path, "w+" )
	if file then
		file:write( json_encode_pretty( save_data ) )
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
	If the save file is missing, empty, or corrupt (invalid JSON / not an object),
	fall back to a fresh config and re-run the first-time HMD setup so the settings
	menu still shows up instead of the mod failing to load.
]]
function VRPlusMod:Load()
	local file = io.open( self._data_path, "r" )
	if file then
		local contents = file:read("*all")
		file:close()

		local ok, decoded = pcall( json.decode, contents )
		if ok and type(decoded) == "table" then
			self._data = decoded
		else
			log("[VRPlus] Config file is empty or corrupt - creating a new settings file and starting first-time setup.")
			self._data = {}
			self._need_to_select_hmd = true
		end
	end
	
	-- Copy in any new properties'
	local need_save = not self._data.defaults_hmd
	local defaults, selected = VRPlusMod:_get_defaults(self._data.defaults_hmd)
	load_defaults(defaults, self._data)

	if need_save and selected then
		self:Save()
	end

	self._need_to_select_hmd = self._need_to_select_hmd or not selected
end

function VRPlusMod:_GetOptionTable(name)
	return name == "_G" and self._data or self._data[name]
end

function VRPlusMod:_ResetDefaultControls(hmd)
	self._need_to_select_hmd = false
	local defaults = VRPlusMod:_get_defaults(hmd)
	self._data = {}
	load_defaults(defaults, self._data)
	self:Save()

	-- Set the values for the GUI controls
	for menu_id, table_data_name in pairs(self._menu_ids) do
		local menu = MenuHelper:GetMenu(menu_id)
		for _, item in ipairs(menu._items_list) do
			if item.set_value then
				local val_name = item:name():sub(8) -- remove vrplus_
				local table_data = self:_GetOptionTable(table_data_name)
				local value = table_data[val_name]

				if item._type == "toggle" then
					item:set_value( value and "on" or "off" )
				else
					item:set_value( value )
				end
			end
		end
	end
end

function VRPlusMod:AskHMDType(cancellable)
	local defaults, selected = VRPlusMod:_get_defaults(self._data.defaults_hmd)
	load_defaults(defaults, self._data)

	local text = function(str) return managers.localization:text(str) end

	local options = {
		{
			text = text("vrplus_rift"),
			callback = function() self:_ResetDefaultControls("Rift") end
		},
		{
			text = text("vrplus_vive"),
			callback = function() self:_ResetDefaultControls("Vive") end
		},
		{
			text = text("vrplus_index"),
			callback = function() self:_ResetDefaultControls("Index") end
		},
		{
			text = text("vrplus_frame"),
			callback = function() self:_ResetDefaultControls("Frame") end
		},
		{
			text = text("vrplus_generic"),
			callback = function() self:_ResetDefaultControls("generic") end
		}
	}

	if cancellable then
		table.insert(options, {
			text = text("vrplus_cancel")
		})
	end

	QuickMenu:new(
		text("vrplus_ask_hmd_type"),
		text("vrplus_ask_hmd_type_message"),
		options
	):Show()
end

function VRPlusMod:OnMenusReady()
	if self._need_to_select_hmd then
		self._need_to_select_hmd = false
		self:AskHMDType(false)
	end
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

	if LANG_KOREAN then
		loc:load_localization_file( VRPlusMod._path .. "lang/kr.lang")
	end

	for key, code in pairs({
		russian = "ru",
		spanish = "es"
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
	local function add_inputs(scope, checkboxes, names, callback)
		for _, name in ipairs(names) do
			MenuCallbackHandler["vrplus_" .. name] = function(self, item)
				local options = VRPlusMod:_GetOptionTable(scope)
				if checkboxes then
					options[name] = (item:value() == "on" and true or false)
				else
					options[name] = item:value()
				end
				VRPlusMod:Save()

				if callback then
					callback(name, item)
				end
			end
		end
	end

	local function reload_hands()
		-- You can adjust settings on the flat version
		-- this would crash in that case
		if managers.vr then
			local hsm = managers.vr:hand_state_machine()
			-- If we're in the main menu, this will be nil
			if hsm then
				-- Apply the changes we made
				hsm:refresh()
			end
		end
	end

	function MenuCallbackHandler:vrplus_reset_options()
		VRPlusMod:AskHMDType(true)
	end

	function MenuCallbackHandler:vrplus_controls_manager()
		-- Show deprecation warning dialog using PAYDAY 2's native system
		local dialog_data = {
			title = "Controls Manager",
			text = "Simple button remapping is now available in the new 'Button Mappings' menu instead.\n" ..
					"Button Mappings always take priority over the Controls Manager\n" ..
			        "The Controls Manager is intended for advanced users who need finer control.",
			button_list = {
				{
					text = "Continue to Advanced Controls Manager",
					callback_func = function()
						managers.menu:open_node("vrplus_controls_manager")
					end
				},
				{
					text = "Cancel",
					cancel_button = true
				}
			}
		}
		managers.system_menu:show(dialog_data)
	end

	-- Checkboxes
	add_inputs("_G", true, {
		"movement_controller_direction",
		"cam_redout_enable",
		"movement_smoothing",
		"teleport_on_release",
	})

	add_inputs("_G", true, {
		"movement_locomotion",
	}, reload_hands)

	-- Sliders and multiselectors
	add_inputs("_G", false, {
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

	-- Rotation delay, amount, and smooth speed - custom handlers for multiple_choice controls
	-- Each option carries its real numeric value via "item_values", so item:value() already
	-- returns the actual value (e.g. 0.15, 45, 180) rather than a list index.
	function MenuCallbackHandler:vrplus_rotation_delay(item)
		VRPlusMod._data.rotation_delay = item:value()
		VRPlusMod:Save()
	end

	function MenuCallbackHandler:vrplus_rotation_amount(item)
		VRPlusMod._data.rotation_amount = item:value()
		VRPlusMod:Save()
	end

	function MenuCallbackHandler:vrplus_smooth_rotation_speed(item)
		VRPlusMod._data.smooth_rotation_speed = item:value()
		VRPlusMod:Save()
	end
	
	-- Controller type selection - with auto-detect option
	function MenuCallbackHandler:vrplus_controller_type(item)
		local index = item:value()  -- This is the 1-based index
		-- Map: 1=Auto, 2=Vive, 3=Touch, 4=Knuckles, 5=Frame
		local controller_types = {
			nil,  -- Auto-detect
			VRPlusMod.C.CONTROLLER_VIVE,
			VRPlusMod.C.CONTROLLER_TOUCH,
			VRPlusMod.C.CONTROLLER_KNUCKLES,
			VRPlusMod.C.CONTROLLER_FRAME
		}
		VRPlusMod._data.controller_type = controller_types[index]
		VRPlusMod:Save()
		
		-- Reload hand states to apply new controller bindings
		if managers.menu._player then
			managers.menu._player:reload_hand_states()
		end
	end

	-- Helper function to check for button mapping conflicts
	local function check_button_conflicts()
		local mappings = {
			{name = "Jump", value = VRPlusMod._data.button_jump, hand = "right"},
			{name = "Crouch", value = VRPlusMod._data.button_crouch, hand = "both"},
			{name = "Pause", value = VRPlusMod._data.button_pause, hand = "left"},
			{name = "Gadget", value = VRPlusMod._data.button_gadget, hand = "weapon"},
			{name = "Fire Mode", value = VRPlusMod._data.button_firemode, hand = "weapon"}
		}
		
		local conflicts = {}
		for i = 1, #mappings do
			for j = i + 1, #mappings do
				local a, b = mappings[i], mappings[j]
				-- Check if same button value
				if a.value == b.value then
					-- Check if hands can conflict
					local can_conflict = false
					if a.hand == "both" or b.hand == "both" then
						can_conflict = true
					elseif a.hand == b.hand then
						can_conflict = true
					elseif (a.hand == "right" and b.hand == "weapon") or (b.hand == "right" and a.hand == "weapon") then
						can_conflict = true  -- Weapon hand is typically right
					elseif (a.hand == "left" and b.hand == "weapon") or (b.hand == "left" and a.hand == "weapon") then
						-- Only conflict if user changed weapon hand to left (rare)
						can_conflict = false
					end
					
					if can_conflict then
						table.insert(conflicts, a.name .. " and " .. b.name)
					end
				end
			end
		end
		
		if #conflicts > 0 then
			local msg = "Button conflict: " .. table.concat(conflicts, ", ") .. " use the same button on overlapping hands"
			-- Show warning in console
			log("[VRPlus] WARNING: " .. msg)
			
			-- Cancel any existing timer
			if VRPlusMod._conflict_timer then
				VRPlusMod._conflict_timer:stop()
				VRPlusMod._conflict_timer = nil
			end
			
			-- Show visual popup warning immediately (next tick, no delay)
			if managers and managers.menu then
				VRPlusMod._conflict_timer = DelayedCalls:Add("vrplus_conflict_warning", 0, function()
					local dialog_data = {
						title = "VRPlus: Button Conflict Detected",
						text = msg .. ".\n\nSome functions may not work as expected. Consider remapping to different buttons.",
						button_list = {
							{text = "OK", is_cancel_button = true}
						},
						id = "vrplus_button_conflict_warning"
					}
					managers.system_menu:show(dialog_data)
					VRPlusMod._conflict_timer = nil
				end)
			end
		end
	end

	-- Button mapping callbacks
	function MenuCallbackHandler:vrplus_button_jump(item)
		VRPlusMod._data.button_jump = item:value()
		VRPlusMod:Save()
		check_button_conflicts()
		if managers.menu._player then
			managers.menu._player:reload_hand_states()
		end
	end

	function MenuCallbackHandler:vrplus_button_crouch(item)
		VRPlusMod._data.button_crouch = item:value()
		VRPlusMod:Save()
		check_button_conflicts()
		if managers.menu._player then
			managers.menu._player:reload_hand_states()
		end
	end

	function MenuCallbackHandler:vrplus_button_pause(item)
		VRPlusMod._data.button_pause = item:value()
		VRPlusMod:Save()
		check_button_conflicts()
		if managers.menu._player then
			managers.menu._player:reload_hand_states()
		end
	end

	function MenuCallbackHandler:vrplus_button_gadget(item)
		VRPlusMod._data.button_gadget = item:value()
		VRPlusMod:Save()
		check_button_conflicts()
		if managers.menu._player then
			managers.menu._player:reload_hand_states()
		end
	end

	function MenuCallbackHandler:vrplus_button_firemode(item)
		VRPlusMod._data.button_firemode = item:value()
		VRPlusMod:Save()
		check_button_conflicts()
		if managers.menu._player then
			managers.menu._player:reload_hand_states()
		end
	end

	-- Comfort options
	add_inputs("comfort", true, {
		"max_movement_speed_enable",
		"interact_lock",
		nil
	})
	add_inputs("comfort", false, {
		"max_movement_speed",
		"crouch_scale",
		nil
	})

	add_inputs("comfort", false, {
		"interact_mode",
		"crouching",
		nil
	}, reload_hands)

	-- HUD options
	add_inputs("hud", true, {
		"watch_health_wheel",
		"belt_radio",
	})

	-- Tweak options
	add_inputs("tweaks", false, {
		"endscreen_speedup",
		"weapon_melee",
	})
	add_inputs("tweaks", true, {
		"force_quality_enable",
	})

	add_inputs("tweaks", false, {
		"force_quality",
	}, function(name, item)
		local quality_level = math.floor(VRPlusMod._data.tweaks.force_quality + 0.5)

		if VRPlusMod._data.tweaks.force_quality ~= quality_level then
			item:set_value( quality_level )
			VRPlusMod._data.tweaks.force_quality = quality_level
			VRPlusMod:Save()
		end
	end)

	local function reload_laser()
		if managers.menu._player then
			-- Make the changes take effeect
			managers.menu._player.__laser_is_updated = false
		end
	end
	add_inputs("tweaks", true, {
		"laser_disco"
	}, reload_laser)
	add_inputs("tweaks", false, {
		"laser_hue"
	}, reload_laser)

	local function addmenu(name, id, src)
		local srctable = VRPlusMod:_GetOptionTable(src)
		MenuHelper:LoadFromJsonFile(VRPlusMod._path .. "menus/" .. name .. ".json", nil, srctable)
		VRPlusMod._menu_ids[id] = src
	end

	--[[
		Load our menu json file and pass it to our MenuHelper so that it can build our in-game menu for us.
		The second option used to be for keybinds, however that seems to not be implemented on BLT2.
		We also pass our data table as the third argument so that our saved values can be loaded from it.
	]]
	MenuHelper:LoadFromJsonFile( VRPlusMod._path .. "menus/mainmenu.json", nil, nil )

	addmenu("camera",		"vrplus_menu_camera",		"_G" )
	addmenu("controllers",	"vrplus_menu_controllers",	"_G" )
	addmenu("buttonmappings",	"vrplus_menu_buttonmappings",	"_G" )
	addmenu("comfort",		"vrplus_menu_comfort",		"comfort" )
	addmenu("hud",			"vrplus_menu_hud",			"hud" )
	addmenu("tweaks",		"vrplus_menu_tweaks",		"tweaks" )

end)
