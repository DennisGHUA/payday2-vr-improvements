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

-- Helper function to get button key name based on button constant
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
		[VRPlusMod.C.BUTTON_DPAD_RIGHT] = "d_right_"
	}
	return (button_map[button_const] or "b_") .. hand_name
end

local function add_offhand_actions(hand_name, key_map)
	local controller_type = get_controller_type()
	
	if VRPlusMod._data.comfort.crouching ~= VRPlusMod.C.CROUCH_NONE then
		if controller_type == VRPlusMod.C.CONTROLLER_VIVE then
			-- Vive: Use menu button for crouch
			key_map["menu_" .. hand_name] = { "duck" }
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
	end

	if VRPlusMod._data.movement_locomotion then
		-- Don't use 'warp' for running/jumping, as it seems somehow tied
		-- to the Rift's 'Y' button.
		
		-- Handle jump based on controller type
		if controller_type == VRPlusMod.C.CONTROLLER_VIVE then
			-- Vive: Place jump function opposite from sprint/walk touchpad
			if hand_name == "r" then
				key_map["trackpad_button_" .. "l"] = { "jump" }
			else
				key_map["trackpad_button_" .. "r"] = { "jump" }
			end
			-- For Vive, only assign run to the current hand's trackpad (not the opposite hand with jump)
			key_map["trackpad_button_" .. hand_name] = { "run" }
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
			key_map["dpad_" .. hand_name] = { "move" }
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

		if not key_map[key] then
			key_map[key] = {}
		end

		table.insert(key_map[key], "interact_" .. nice_name)
	end

	if VRPlusMod._data.comfort.interact_mode == VRPlusMod.C.INTERACT_TRIGGER then
		key_map["grip_" .. hand_name][1] = nil
	end

	if VRPlusMod._data.movement_locomotion then
		-- Prevent moving forwards from jumping for Rift users
		key_map["d_up_" .. hand_name] = nil
	end

	add_offhand_actions(hand_name, key_map)
end)

Hooks:PostHook(PointHandState, "apply", "VRPlusPointingHandActions", function(self, hand, key_map)
	local hand_name = hand == 1 and "r" or "l"

	if VRPlusMod._data.movement_locomotion then
		-- Prevent moving forwards from jumping for Rift users
		key_map["d_up_" .. hand_name] = nil
	end

	add_offhand_actions(hand_name, key_map)
end)

Hooks:PostHook(MaskHandState, "apply", "VRPlusCasingRotation", function(self, hand, key_map)
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

	local hand_name = hand == 1 and "r" or "l"

	key_map["dpad_" .. hand_name] = { "touchpad_primary" }
end)

Hooks:PostHook(BeltHandState, "apply", "VRPlusBeltActions", function(self, hand, key_map)
	local weapon_hand = managers.vr:get_setting("default_weapon_hand"):sub(1,1)
	local hand_name = hand == 1 and "r" or "l"

	if VRPlusMod._data.turning_mode ~= VRPlusMod.C.TURNING_OFF and hand_name == weapon_hand then
		key_map["dpad_" .. hand_name] = { "touchpad_primary" }
	end

	if hand_name ~= weapon_hand then
		add_offhand_actions(hand_name, key_map)
	end
end)

Hooks:PostHook(WeaponHandState, "apply", "VRPlusMoveGadgetFiremode", function(self, hand, key_map)
	if VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then
		return
	end

	-- By default:
	-- switch_hands -> d_up (HARDCODED - cannot be changed)
	-- weapon_firemode -> d_left (now customizable)
	-- weapon_gadget -> d_right (now customizable)

	local hand_name = hand == 1 and "r" or "l"
	local controller_type = get_controller_type()
	
	-- Clear customizable d-pad mappings (but leave d_up for switch_hands)
	key_map["d_left_" .. hand_name] = nil
	key_map["d_right_" .. hand_name] = nil
	key_map["d_down_" .. hand_name] = nil
	-- DO NOT clear d_up - it's hardcoded to "switch_hands" by the game
	
	-- Apply user-configured button mappings for gadget and fire mode
	local gadget_button = VRPlusMod._data.button_gadget or VRPlusMod.C.BUTTON_DPAD_RIGHT
	local firemode_button = VRPlusMod._data.button_firemode or VRPlusMod.C.BUTTON_DPAD_LEFT
	
	local gadget_key = get_button_key(gadget_button, hand_name)
	local firemode_key = get_button_key(firemode_button, hand_name)
	
	-- Only apply if the button isn't d_up (reserved for switch_hands)
	if gadget_button ~= VRPlusMod.C.BUTTON_DPAD_UP then
		key_map[gadget_key] = { "weapon_gadget" }
	end
	if firemode_button ~= VRPlusMod.C.BUTTON_DPAD_UP then
		key_map[firemode_key] = { "weapon_firemode" }
	end
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
