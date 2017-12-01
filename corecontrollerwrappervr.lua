--[[
	CoreControllerWrapperVR

	If view rotation is enabled, move gadget and firemode selectors
	This automagically remaps them
--]]

core:module("CoreControllerWrapperVR")

local function remap_name(name)
	-- If we're in anything but the default turning mode, remap the inputs
	if _G.VRPlusMod._data.turning_mode == _G.VRPlusMod.C.TURNING_OFF then
		return name
	end

	-- By default
	-- switch_hands -> up
	-- weapon_firemode -> left
	-- weapon_gadget ->  right
	-- menu_snap -> down

	-- TODO swap gadget and firemode
	-- For some bizzare reason, it wasn't working on my end

	-- TODO remove these when basegame snapturning is confirmed to work
	local target = ({
		switch_hands = "weapon_firemode",
		weapon_firemode = "switch_hands",
		weapon_gadget = "menu_snap",
		menu_snap = "weapon_gadget",
	})[name] or name

	return target
end

for _, name in ipairs({
	"get_input_bool",
	"get_input_pressed",
	"get_input_released",
	"get_input_axis"
}) do
	local old_func = ControllerWrapperVR[name]
	assert(old_func, name .. " missing!")
	ControllerWrapperVR[name] = function(self, connection, ...)
		return old_func(self, remap_name(connection), ...)
	end
end
