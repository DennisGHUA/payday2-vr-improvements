--[[
	Hand States Player

	Apply the custom control scheme as set by the player.

	This also applies the older fixed-style customisations, which I'd
	like to find an elegant replacement for, as tick-box customisation is
	quicker/easier for the user than mapping the controls across several differnt
	states.
]]

-- The fixed customisations
-- Register these first so user-defined customisations override
--  these, not vise-versa.
-- Note these apply to the defaults (but NOT in the UI), so if the user resets
--  the customisation for a control it will still include these.
-- TODO make these appear in the defaults in some way
-- TODO add some kind of note in the UI to indicate such changes.

-- Helper function to detect controller type
local function get_controller_type()
	-- Use user-selected controller type if set
	if VRPlusMod._data.controller_type then
		return VRPlusMod._data.controller_type
	end
	
	-- Auto-detect based on HMD brand
	local brand = blt_vr and blt_vr.gethmdbrand() or "generic"
	if brand == "Oculus" then
		return VRPlusMod.C.CONTROLLER_TOUCH
	elseif brand == "Index" then
		return VRPlusMod.C.CONTROLLER_KNUCKLES
	elseif brand == "HTC" then
		return VRPlusMod.C.CONTROLLER_VIVE
	elseif brand == "Valve" then
		return VRPlusMod.C.CONTROLLER_FRAME
	end
	
	-- Default to Touch (Quest/Rift) for unknown headsets as it's most common
	-- and button-based controllers are more prevalent than touchpad-only
	return VRPlusMod.C.CONTROLLER_TOUCH
end

local function get_button_key(button_const, hand_name)
	local button_map = {
		[VRPlusMod.C.BUTTON_A] = "a_",
		[VRPlusMod.C.BUTTON_B] = "b_",
		[VRPlusMod.C.BUTTON_X] = "x_",
		[VRPlusMod.C.BUTTON_Y] = "y_",
		[VRPlusMod.C.BUTTON_MENU] = "menu_",
		[VRPlusMod.C.BUTTON_DPAD_UP] = "d_up_",
		[VRPlusMod.C.BUTTON_DPAD_DOWN] = "d_down_",
		[VRPlusMod.C.BUTTON_DPAD_LEFT] = "d_left_",
		[VRPlusMod.C.BUTTON_DPAD_RIGHT] = "d_right_",

		-- Vive touchpad buttons
		[VRPlusMod.C.BUTTON_TOUCHPAD_UP_OFF] = "d_up_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_DOWN_OFF] = "d_down_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_LEFT_OFF] = "d_left_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_RIGHT_OFF] = "d_right_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_CENTER_OFF] = "trackpad_button_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_MENU_OFF] = "menu_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_UP_DOMINANT] = "d_up_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_DOWN_DOMINANT] = "d_down_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_LEFT_DOMINANT] = "d_left_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_RIGHT_DOMINANT] = "d_right_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_CENTER_DOMINANT] = "trackpad_button_",
		[VRPlusMod.C.BUTTON_TOUCHPAD_MENU_DOMINANT] = "menu_"
	}
	return (button_map[button_const] or "b_") .. hand_name
end

local function value_to_hand(button_const, hand_name, weapon_hand, offhand)
	if button_const >= VRPlusMod.C.BUTTON_TOUCHPAD_UP_OFF and button_const <= VRPlusMod.C.BUTTON_TOUCHPAD_MENU_OFF then
		return offhand
	elseif button_const >= VRPlusMod.C.BUTTON_TOUCHPAD_UP_DOMINANT and button_const <= VRPlusMod.C.BUTTON_TOUCHPAD_MENU_DOMINANT then
		return weapon_hand
	end
	return hand_name
end

-- Resolve the current dominant hand and offhand
local function get_hand_context()
	local weapon_hand = managers.vr and managers.vr:get_setting("default_weapon_hand"):sub(1,1) or "r"
	local offhand = weapon_hand == "r" and "l" or "r"
	return weapon_hand, offhand
end

local function has_user_override(state, input_id)
	local rebindings = VRPlusMod._data.control_rebindings
	return rebindings and rebindings[state] and rebindings[state][input_id] ~= nil
end

local function has_override(state, key_name)
	if get_controller_type() ~= VRPlusMod.C.CONTROLLER_VIVE then
		return false
	end

	-- Strip the hand suffix ("menu_r" -> "menu") to get the bare input id
	local input_id = key_name:match("^(.-)_[lr]$")
	return input_id and has_user_override(state, input_id)
end

local function add_offhand_actions(hand_name, key_map, state)
	local controller_type = get_controller_type()
	local weapon_hand, offhand = get_hand_context()

	if VRPlusMod._data.comfort.crouching ~= VRPlusMod.C.CROUCH_NONE then
		if controller_type == VRPlusMod.C.CONTROLLER_VIVE then
			-- Vive: user-mappable crouch (default: menu button on the offhand,
			-- matching the 0.7.3 layout)
			local crouch_button = VRPlusMod._data.button_crouch or VRPlusMod.C.BUTTON_TOUCHPAD_MENU_OFF
			local crouch_hand = value_to_hand(crouch_button, hand_name, weapon_hand, offhand)
			local button_key = get_button_key(crouch_button, crouch_hand)
			if not has_override(state, button_key) then
				key_map[button_key] = { "duck" }
			end
		elseif controller_type == VRPlusMod.C.CONTROLLER_TOUCH or 
		       controller_type == VRPlusMod.C.CONTROLLER_KNUCKLES or 
		       controller_type == VRPlusMod.C.CONTROLLER_FRAME then
			-- Button-based controllers: Use user-configured button for crouch
			local crouch_button = VRPlusMod._data.button_crouch or VRPlusMod.C.BUTTON_A
			local button_key = get_button_key(crouch_button, hand_name)
			key_map[button_key] = { "duck" }
		end
	end
	
	-- Map pause button for button-based controllers
	if controller_type == VRPlusMod.C.CONTROLLER_TOUCH or 
	   controller_type == VRPlusMod.C.CONTROLLER_KNUCKLES or 
	   controller_type == VRPlusMod.C.CONTROLLER_FRAME then
		local pause_button = VRPlusMod._data.button_pause or VRPlusMod.C.BUTTON_Y
		local button_key = get_button_key(pause_button, hand_name)
		-- Map to menu/ESC action (only on non-weapon hand to avoid conflicts during gameplay)
		if hand_name == "l" then
			key_map[button_key] = key_map[button_key] or {}
			table.insert(key_map[button_key], "menu")
		end
	elseif controller_type == VRPlusMod.C.CONTROLLER_VIVE then
		local pause_button = VRPlusMod._data.button_pause or VRPlusMod.C.BUTTON_TOUCHPAD_MENU_DOMINANT
		local pause_hand = value_to_hand(pause_button, hand_name, weapon_hand, offhand)

		local should_bind = pause_hand == hand_name
		if not should_bind and pause_hand == weapon_hand then
			should_bind = hand_name == offhand
		end

		if should_bind then
			local button_key = get_button_key(pause_button, pause_hand)
			if not has_override(state, button_key) then
				if not key_map[button_key] then
					key_map[button_key] = {}
				end
				if not table.contains(key_map[button_key], "menu") then
					table.insert(key_map[button_key], "menu")
				end
			end
		end
	end

	if VRPlusMod._data.movement_locomotion then
		-- Don't use 'warp' for running/jumping, as it seems somehow tied
		-- to the Rift's 'Y' button.
		
		-- Handle jump based on controller type
		if controller_type == VRPlusMod.C.CONTROLLER_VIVE then
			local jump_button = VRPlusMod._data.button_jump or VRPlusMod.C.BUTTON_TOUCHPAD_CENTER_DOMINANT
			local jump_hand = value_to_hand(jump_button, hand_name, weapon_hand, offhand)
			local jump_key = get_button_key(jump_button, jump_hand)
			if not has_override(state, "trackpad_button_" .. hand_name) then
				key_map["trackpad_button_" .. hand_name] = { "run" }
			end
			if not has_override(state, jump_key) then
				key_map[jump_key] = { "jump" }
			end
		elseif controller_type == VRPlusMod.C.CONTROLLER_TOUCH or 
		       controller_type == VRPlusMod.C.CONTROLLER_KNUCKLES or 
		       controller_type == VRPlusMod.C.CONTROLLER_FRAME then
			-- Button-based controllers: Use user-configured button for jump
			local jump_button = VRPlusMod._data.button_jump or VRPlusMod.C.BUTTON_B
			if hand_name == "r" then
				local button_key = get_button_key(jump_button, hand_name)
				key_map[button_key] = { "jump" }
			end
			-- For button-based controllers, trackpad/thumbstick is always for run (no conflict with jump)
			key_map["trackpad_button_" .. hand_name] = { "run" }
		end

		-- Only map dpad to move for Vive (button-based controllers may use dpad for other actions)
		if controller_type == VRPlusMod.C.CONTROLLER_VIVE then
			if not has_override(state, "dpad_" .. hand_name) then
				key_map["dpad_" .. hand_name] = { "move" }
			end
		end

	end
end

-----------------------------------------
-- Advanced Controls Manager customisations --
-----------------------------------------
-- The Advanced Controls Manager (fine-grained rebindings) is applied FIRST so
-- the "Button Mappings" menu hooks below override it. Any button assigned by
-- Button Mappings takes priority over the Controls Manager when both bind the
-- same input.

-- List of the states the player can edit
-- Some are disabled as they're not used in-game and their inclusion
--  would be confusing to players.
-- Updates may require us to add to these
-- TODO i18n?
local states = {
	"Empty",
	"Point",
	"Weapon",
	"Akimbo",
	"Mask",
	"Item",
	"Ability",
	"Equipment",
	"Tablet",
	"Belt",
	--"Repeater",
	"Driving",
	--"Arrow",
}

-- Make these available to the control manager UI
VRPlusMod._ControlManager._handstatesplayerdata = {
	states = states
}

for _, state in ipairs(states) do
	local class = _G[state .. "HandState"]

	Hooks:PostHook(class, "apply", "VRPlusCustomInputs_" .. state, function(self, hand, key_map)
		local hand_name = hand == 1 and "r" or "l"

		-- Grab the customisations
		-- The format of the table is as follows:
		--[[
{
	menu = { -- The ID of the button, minus the _l or _r suffix indicating which
	         --  hand it's on
		reload = {}, -- The action to be taken, and what special settings it has
		toggle_menu = { hand = 2 }, -- Only apply this input to the left hand
	}
}
		--]]

		-- If no controls are set, stop here
		if not VRPlusMod._data.control_rebindings then return end

		-- Grab the controls for this state
		local rebindings = VRPlusMod._data.control_rebindings[state]
		if not rebindings then return end

		for input_id, actions in pairs(rebindings) do
			-- The list of actions to be taken (running with out previous example,
			--  this would be {"reload"} or {"reload", "toggle_menu"} depending on
			--  which hand this is being bound to
			local result_action_list = {}

			-- The input ID as used by the game, eg menu_l or menu_r
			local handed_input_id = input_id .. "_" .. hand_name

			for action, action_data in pairs(actions) do
				local actinfo = VRPlusMod._ControlManager.Data.actions[action]
				local action_id

				if actinfo.right then
					-- If there is a special set of action IDs depending on
					--  the hand, match for those
					action_id = hand == 1 and actinfo.right or actinfo.left
				else
					action_id = action
				end

				-- If the action is not limited to one particular hand, or if
				--  it's limited to the hand we're currently setting up, add
				--  it to the list of actions to take when this input is used
				if not action_data.hand or action_data.hand == hand then
					table.insert(result_action_list, action_id)
				end
			end

			-- Set the resulting items to nil if we don't have any actions
			--  bound to this input, otherwise set it to the list we just compiled
			key_map[handed_input_id] = #result_action_list == 0 and nil or result_action_list
		end
	end)
end

-- Note EmptyHandState deals with everything for your non-weapon hand.
-- including shouting down civs, bagging loot, etc.
Hooks:PostHook(EmptyHandState, "apply", "VRPlusOffHandActions", function(self, hand, key_map)
	local hand_name = hand == 1 and "r" or "l"
	local nice_name = hand == 1 and "right" or "left"

	if VRPlusMod._data.comfort.interact_mode ~= VRPlusMod.C.INTERACT_GRIP then
		-- TODO should we just override it completely?
		local key = "trigger_" .. hand_name

		if not has_override("Empty", key) then
			if not key_map[key] then
				key_map[key] = {}
			end

			table.insert(key_map[key], "interact_" .. nice_name)
		end
	end

	if VRPlusMod._data.comfort.interact_mode == VRPlusMod.C.INTERACT_TRIGGER then
		if not has_override("Empty", "grip_" .. hand_name) then
			key_map["grip_" .. hand_name][1] = nil
		end
	end

	if VRPlusMod._data.movement_locomotion then
		-- Prevent moving forwards from jumping for Rift users
		if not has_override("Empty", "d_up_" .. hand_name) then
			key_map["d_up_" .. hand_name] = nil
		end
	end

	add_offhand_actions(hand_name, key_map, "Empty")
end)

Hooks:PostHook(PointHandState, "apply", "VRPlusPointingHandActions", function(self, hand, key_map)
	local hand_name = hand == 1 and "r" or "l"

	if VRPlusMod._data.movement_locomotion then
		-- Prevent moving forwards from jumping for Rift users
		if not has_override("Point", "d_up_" .. hand_name) then
			key_map["d_up_" .. hand_name] = nil
		end
	end

	add_offhand_actions(hand_name, key_map, "Point")
end)

Hooks:PostHook(MaskHandState, "apply", "VRPlusCasingRotation", function(self, hand, key_map)
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

	local hand_name = hand == 1 and "r" or "l"

	if not has_override("Mask", "dpad_" .. hand_name) then
		key_map["dpad_" .. hand_name] = { "touchpad_primary" }
	end
end)

Hooks:PostHook(BeltHandState, "apply", "VRPlusBeltActions", function(self, hand, key_map)
	local weapon_hand = managers.vr:get_setting("default_weapon_hand"):sub(1,1)
	local hand_name = hand == 1 and "r" or "l"

	if VRPlusMod._data.turning_mode ~= VRPlusMod.C.TURNING_OFF and hand_name == weapon_hand then
		if not has_override("Belt", "dpad_" .. hand_name) then
			key_map["dpad_" .. hand_name] = { "touchpad_primary" }
		end
	end

	if hand_name ~= weapon_hand then
		add_offhand_actions(hand_name, key_map, "Belt")
	end
end)

Hooks:PostHook(WeaponHandState, "apply", "VRPlusMoveGadgetFiremode", function(self, hand, key_map)
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then
		return
	end

	local hand_name = hand == 1 and "r" or "l"
	local controller_type = get_controller_type()

	if controller_type == VRPlusMod.C.CONTROLLER_VIVE then
		local weapon_hand, offhand = get_hand_context()

		local gadget_button = VRPlusMod._data.button_gadget or VRPlusMod.C.BUTTON_TOUCHPAD_UP_DOMINANT
		local firemode_button = VRPlusMod._data.button_firemode or VRPlusMod.C.BUTTON_TOUCHPAD_DOWN_DOMINANT

		local gadget_hand = value_to_hand(gadget_button, hand_name, weapon_hand, offhand)
		local firemode_hand = value_to_hand(firemode_button, hand_name, weapon_hand, offhand)

		local function apply(key, value)
			if not has_override("Weapon", key) then
				key_map[key] = value
			end
		end

		apply("d_left_" .. hand_name, nil)
		apply("d_right_" .. hand_name, nil)
		apply("d_up_" .. hand_name, nil)
		apply("d_down_" .. hand_name, nil)

		apply(get_button_key(gadget_button, gadget_hand), { "weapon_gadget" })
		apply(get_button_key(firemode_button, firemode_hand), { "weapon_firemode" })
		return
	end

	-- Clear the d-pad mappings we own, so unbound directions do nothing
	key_map["d_left_" .. hand_name] = nil
	key_map["d_right_" .. hand_name] = nil
	key_map["d_down_" .. hand_name] = nil

	-- Apply user-configured button mappings for gadget and fire mode
	local gadget_button = VRPlusMod._data.button_gadget or VRPlusMod.C.BUTTON_DPAD_RIGHT
	local firemode_button = VRPlusMod._data.button_firemode or VRPlusMod.C.BUTTON_DPAD_LEFT
	
	local gadget_key = get_button_key(gadget_button, hand_name)
	local firemode_key = get_button_key(firemode_button, hand_name)
	
	key_map[gadget_key] = { "weapon_gadget" }
	key_map[firemode_key] = { "weapon_firemode" }
end)

-----------------------------------------
-- Controller-type default bindings ----
-----------------------------------------

for _, state in ipairs(states) do
	local class = _G[state .. "HandState"]

	-- Controller-specific bindings based on controller type
	Hooks:PostHook(class, "apply", "VRPlusControllerSpecificBindings_" .. state, function(self, hand, key_map)
		local controller_type = get_controller_type()
		local hand_name = hand == 1 and "r" or "l"
		
		-- Only apply button-based bindings for Quest/Index/Frame controllers
		if controller_type == VRPlusMod.C.CONTROLLER_TOUCH or 
		   controller_type == VRPlusMod.C.CONTROLLER_KNUCKLES or 
		   controller_type == VRPlusMod.C.CONTROLLER_FRAME then
			-- Quest/Rift/Index/Frame: Button-based controls
			if hand == 1 then -- Right Hand
				-- B button for crouch (if crouch is enabled)
				if VRPlusMod._data.comfort.crouching ~= VRPlusMod.C.CROUCH_NONE then
					key_map["menu_r"] = { "duck" }
				end
				-- A button for jump (already handled in add_offhand_actions, but ensure it's set)
				if VRPlusMod._data.movement_locomotion then
					key_map["a_r"] = { "jump" }
				end
			elseif hand == 2 then -- Left Hand
				-- B/Y button for toggle menu (Quest uses Y, Index/Frame use B)
				key_map["menu_l"] = { "toggle_menu" }
			end
		end
		-- Vive controllers don't need special button bindings as they use touchpads
	end)
end
