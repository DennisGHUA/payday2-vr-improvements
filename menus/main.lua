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

	-- Vive wand touchpad mapping options
	-- "(Offhand)" = the hand that is not holding the weapon
	BUTTON_TOUCHPAD_UP_OFF = 10,
	BUTTON_TOUCHPAD_DOWN_OFF = 11,
	BUTTON_TOUCHPAD_LEFT_OFF = 12,
	BUTTON_TOUCHPAD_RIGHT_OFF = 13,
	BUTTON_TOUCHPAD_CENTER_OFF = 14, -- touchpad center click
	BUTTON_TOUCHPAD_MENU_OFF = 15,   -- menu button on the offhand
	-- "(Dominant hand)" = the hand currently holding the weapon
	BUTTON_TOUCHPAD_UP_DOMINANT = 16,
	BUTTON_TOUCHPAD_DOWN_DOMINANT = 17,
	BUTTON_TOUCHPAD_LEFT_DOMINANT = 18,
	BUTTON_TOUCHPAD_RIGHT_DOMINANT = 19,
	BUTTON_TOUCHPAD_CENTER_DOMINANT = 20, -- touchpad center click
	BUTTON_TOUCHPAD_MENU_DOMINANT = 21,   -- menu button on the dominant hand

	nil
}

-- Load the default options
dofile(ModPath .. "menus/defaults.lua")

VRPlusMod._path = ModPath
VRPlusMod._data_path = SavePath .. "vr_improvements.conf"
VRPlusMod._data = {}
VRPlusMod._menu_ids = {}

-- The mod version a config was written with, so old ones can be fixed up on load.
-- Deliberately not in defaults.lua: those only fill in missing keys, which would
-- stamp old configs as current and skip their migrations.
local MOD_VERSION = ModInstance and ModInstance:GetVersion() or "0"

-- ponytail: assumes version parts stay below 100. Swap for a part-by-part compare
-- if that ever stops holding.
local function version_number(version)
	local major, minor, patch = tostring(version):match("(%d+)%.?(%d*)%.?(%d*)")
	return (tonumber(major) or 0) * 10000 + (tonumber(minor) or 0) * 100 + (tonumber(patch) or 0)
end

-- Every button a mapping can be put on, in the order the picker lists them
VRPlusMod.BUTTON_OPTIONS = {
	{ value = VRPlusMod.C.BUTTON_A, text = "vrplus_button_a" },
	{ value = VRPlusMod.C.BUTTON_B, text = "vrplus_button_b" },
	{ value = VRPlusMod.C.BUTTON_X, text = "vrplus_button_x" },
	{ value = VRPlusMod.C.BUTTON_Y, text = "vrplus_button_y" },
	{ value = VRPlusMod.C.BUTTON_MENU, text = "vrplus_button_menu" },
	{ value = VRPlusMod.C.BUTTON_DPAD_UP, text = "vrplus_button_dpad_up" },
	{ value = VRPlusMod.C.BUTTON_DPAD_DOWN, text = "vrplus_button_dpad_down" },
	{ value = VRPlusMod.C.BUTTON_DPAD_LEFT, text = "vrplus_button_dpad_left" },
	{ value = VRPlusMod.C.BUTTON_DPAD_RIGHT, text = "vrplus_button_dpad_right" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_UP_OFF, text = "vrplus_button_touchpad_up_off" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_DOWN_OFF, text = "vrplus_button_touchpad_down_off" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_LEFT_OFF, text = "vrplus_button_touchpad_left_off" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_RIGHT_OFF, text = "vrplus_button_touchpad_right_off" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_CENTER_OFF, text = "vrplus_button_touchpad_center_off" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_MENU_OFF, text = "vrplus_button_touchpad_menu_off" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_UP_DOMINANT, text = "vrplus_button_touchpad_up_dominant" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_DOWN_DOMINANT, text = "vrplus_button_touchpad_down_dominant" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_LEFT_DOMINANT, text = "vrplus_button_touchpad_left_dominant" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_RIGHT_DOMINANT, text = "vrplus_button_touchpad_right_dominant" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_CENTER_DOMINANT, text = "vrplus_button_touchpad_center_dominant" },
	{ value = VRPlusMod.C.BUTTON_TOUCHPAD_MENU_DOMINANT, text = "vrplus_button_touchpad_menu_dominant" }
}

VRPlusMod.BUTTON_MAPPINGS = {
	"button_jump",
	"button_crouch",
	"button_pause",
	"button_gadget",
	"button_firemode"
}

--[[
	The button mapping items are buttons that open a picker, so the current binding
	has to be part of their label. Registers "vrplus_<mapping>_label" for each one.
]]
function VRPlusMod:UpdateButtonLabels(loc)
	loc = loc or managers.localization

	local strings = {}

	for _, name in ipairs(self.BUTTON_MAPPINGS) do
		local bound = "-"

		for _, option in ipairs(self.BUTTON_OPTIONS) do
			if option.value == self._data[name] then
				bound = loc:text(option.text)
			end
		end

		strings["vrplus_" .. name .. "_label"] = loc:text("vrplus_" .. name) .. ": " .. bound
	end

	loc:add_localized_strings(strings)
end

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

	local config_version = version_number(self._data.config_version)

	if config_version < version_number("0.8.1") then
		-- 0.8.0 defaulted gadget and fire mode onto the stick directions that turn the view
		if self._data.button_gadget == VRPlusMod.C.BUTTON_DPAD_RIGHT then
			self._data.button_gadget = VRPlusMod.C.BUTTON_TOUCHPAD_UP_DOMINANT
		end
		if self._data.button_firemode == VRPlusMod.C.BUTTON_DPAD_LEFT then
			self._data.button_firemode = VRPlusMod.C.BUTTON_TOUCHPAD_DOWN_DOMINANT
		end
	end

	if self._data.config_version ~= MOD_VERSION then
		self._data.config_version = MOD_VERSION
		need_save = true
	end

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
	self._data.config_version = MOD_VERSION
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

	self:UpdateButtonLabels()
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

	VRPlusMod:UpdateButtonLabels(loc)
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
		-- The method check also catches the stub Data.lua installs while reading defaults
		if managers.vr and managers.vr.hand_state_machine then
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
			text = "Simple button remapping is available in the 'Button Mappings' menu instead.\n\n" ..
					"This manager is applied after that menu, so an input you rebind here wins " ..
					"over anything Button Mappings put on it.\n" ..
					"It is meant for advanced users who need per hand state control.",
			button_list = {
				{
					text = "Continue to Advanced Controls Manager",
					callback_func = function()
						-- Selecting the node from inside the dialog is undone when the
						-- dialog closes, so open it on the next tick
						DelayedCalls:Add("vrplus_open_controls_manager", 0, function()
							managers.menu:open_node("vrplus_controls_manager")
						end)
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
		
		-- Reload hand states to apply the newly selected controller bindings
		reload_hands()
	end

	-- Helper function to check for button mapping conflicts
	local function check_button_conflicts()
		local mappings = {
			-- With the unified value set (A/B/X/Y, D-Pad, and touchpad options
			-- for both offhand and dominant hand), any two equal values bind
			-- the same physical input, so every pair can conflict.
			{name = "Jump", value = VRPlusMod._data.button_jump, hand = "both"},
			{name = "Crouch", value = VRPlusMod._data.button_crouch, hand = "both"},
			{name = "Pause", value = VRPlusMod._data.button_pause, hand = "both"},
			{name = "Gadget", value = VRPlusMod._data.button_gadget, hand = "both"},
			{name = "Fire Mode", value = VRPlusMod._data.button_firemode, hand = "both"}
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

	-- Each mapping is a button that opens this picker: 17 options is far too many to
	-- cycle through one by one
	local function show_button_picker(name)
		local dialog_data = {
			title = managers.localization:text("vrplus_" .. name .. "_label"),
			text = managers.localization:text("vrplus_" .. name .. "_desc"),
			button_list = {}
		}

		for _, option in ipairs(VRPlusMod.BUTTON_OPTIONS) do
			table.insert(dialog_data.button_list, {
				text = managers.localization:text(option.text),
				callback_func = function()
					VRPlusMod._data[name] = option.value
					VRPlusMod:Save()
					VRPlusMod:UpdateButtonLabels()
					check_button_conflicts()
					-- Reload hand states to apply the newly selected button bindings
					reload_hands()
					MenuCallbackHandler:refresh_node()
				end
			})
		end

		table.insert(dialog_data.button_list, {
			text = managers.localization:text("dialog_cancel"),
			cancel_button = true
		})

		managers.system_menu:show(dialog_data)
	end

	for _, name in ipairs(VRPlusMod.BUTTON_MAPPINGS) do
		MenuCallbackHandler["vrplus_" .. name] = function()
			show_button_picker(name)
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
		"tablet_heist_info",
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
