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
	if brand == "Oculus" or brand == "Meta" then
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
	-- The game only exposes two face-button inputs per hand: "a_" (lower, A/X) and
	-- "menu_" (upper, B/Y). There are no "b_"/"x_"/"y_" inputs to bind to.
	local button_map = {
		[VRPlusMod.C.BUTTON_A] = "a_",
		[VRPlusMod.C.BUTTON_B] = "menu_",
		[VRPlusMod.C.BUTTON_X] = "a_",
		[VRPlusMod.C.BUTTON_Y] = "menu_",
		[VRPlusMod.C.BUTTON_MENU] = "menu_",
		[VRPlusMod.C.BUTTON_DPAD_UP] = "d_up_",
		[VRPlusMod.C.BUTTON_DPAD_DOWN] = "d_down_",
		[VRPlusMod.C.BUTTON_DPAD_LEFT] = "d_left_",
		[VRPlusMod.C.BUTTON_DPAD_RIGHT] = "d_right_",

		-- Stick/touchpad options. Same inputs as the d-pad ones above, the game has
		-- only one direction group per hand, these just name the hand to bind on.
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
		[VRPlusMod.C.BUTTON_TOUCHPAD_MENU_DOMINANT] = "menu_",
		[VRPlusMod.C.BUTTON_TRIGGER_OFF] = "trigger_",
		[VRPlusMod.C.BUTTON_TRIGGER_DOMINANT] = "trigger_"
	}
	return (button_map[button_const] or "a_") .. hand_name
end

-- Hand a Button Mappings option binds on. Every option resolves to a definite hand:
-- the side the player picked, the controller a face button physically sits on, or
-- both hands for the ones that exist on both.
local function target_hand(button_const, hand_name, weapon_hand, offhand)
	local C = VRPlusMod.C

	if button_const == C.BUTTON_A or button_const == C.BUTTON_B then
		return "r"
	elseif button_const == C.BUTTON_X or button_const == C.BUTTON_Y then
		return "l"
	elseif button_const >= C.BUTTON_TOUCHPAD_UP_OFF and button_const <= C.BUTTON_TOUCHPAD_MENU_OFF then
		return offhand
	elseif button_const >= C.BUTTON_TOUCHPAD_UP_DOMINANT and button_const <= C.BUTTON_TOUCHPAD_MENU_DOMINANT then
		return weapon_hand
	elseif button_const == C.BUTTON_TRIGGER_OFF then
		return offhand
	elseif button_const == C.BUTTON_TRIGGER_DOMINANT then
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

-- Binds a Button Mappings action, and only on the hand currently being applied:
-- writing another hand's keys is unsafe, as that hand's own states may be applied
-- afterwards and reset them. `claimed` keeps the first mapping on an input, so two
-- mappings landing on one button don't silently drop the earlier one.
local function bind_button(key_map, claimed, hand_name, button_const, actions)
	local weapon_hand, offhand = get_hand_context()

	if target_hand(button_const, hand_name, weapon_hand, offhand) ~= hand_name then
		return
	end

	local key = get_button_key(button_const, hand_name)

	if claimed[key] then
		return
	end

	claimed[key] = true
	key_map[key] = actions
end

-- Applies the Button Mappings menu to one hand. Every mapping has a definite hand,
-- so this runs in every state. Order matches the menu, so on a clash the entry the
-- player sees first is the one that keeps the button.
local function add_mapped_buttons(hand_name, key_map)
	local C = VRPlusMod.C
	local data = VRPlusMod._data
	local vive = get_controller_type() == C.CONTROLLER_VIVE
	local claimed = {}

	-- Jump is bound in every movement mode while the "Enable Jump Button" option
	-- is on: with locomotion on it feeds the WarpIdleState jump, with locomotion
	-- off (vanilla Dash/Direct/Dash+Direct) it feeds the vanilla-movement fallback
	-- in PlayerStandardVR:_check_action_jump. The dominant-hand defaults below
	-- don't clash with vanilla movement bindings, which sit on the offhand trackpad.
	if data.jump_enabled ~= false then
		local jump = data.button_jump or (vive and C.BUTTON_TOUCHPAD_CENTER_DOMINANT or C.BUTTON_B)
		bind_button(key_map, claimed, hand_name, jump, { "jump" })
	end

	if data.comfort.crouching ~= C.CROUCH_NONE then
		local crouch = data.button_crouch or (vive and C.BUTTON_TOUCHPAD_MENU_OFF or C.BUTTON_A)
		bind_button(key_map, claimed, hand_name, crouch, { "duck" })
	end

	local pause = data.button_pause or (vive and C.BUTTON_TOUCHPAD_MENU_DOMINANT or C.BUTTON_Y)
	bind_button(key_map, claimed, hand_name, pause, { "toggle_menu" })

	local gadget = data.button_gadget or C.BUTTON_TOUCHPAD_UP_DOMINANT
	local firemode = data.button_firemode or C.BUTTON_TOUCHPAD_DOWN_DOMINANT
	bind_button(key_map, claimed, hand_name, gadget, { "weapon_gadget" })
	bind_button(key_map, claimed, hand_name, firemode, { "weapon_firemode" })
end

local function add_offhand_actions(hand_name, key_map)
	if VRPlusMod._data.movement_locomotion then
		-- Don't use 'warp' for running/jumping, as it seems somehow tied
		-- to the Rift's 'Y' button.
		key_map["trackpad_button_" .. hand_name] = { "run" }

		-- Locomotion axis. Every controller type needs this: WarpIdleState reads the
		-- "move" connection and nothing else binds it, so without it the stick is dead.
		key_map["dpad_" .. hand_name] = { "move" }
	end
end

-----------------------------------------
-- Player hand states we can customise --
-----------------------------------------

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

Hooks:PostHook(WeaponHandState, "apply", "VRPlusClearTurnDirections", function(self, hand, key_map)
	-- Vanilla puts fire mode, gadget, use item and throw grenade on the four stick
	-- directions. All four are dropped so the mappings below are the only thing there.
	local hand_name = hand == 1 and "r" or "l"

	for _, direction in ipairs({ "d_left_", "d_right_", "d_up_", "d_down_" }) do
		key_map[direction .. hand_name] = nil
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
			local weapon_hand, offhand = get_hand_context()

			-- Vanilla puts the menu on the upper button of both hands, which fires it
			-- twice. Keep the offhand one only.
			if hand_name == weapon_hand then
				key_map["menu_" .. hand_name] = nil
			elseif hand_name == offhand then
				key_map["menu_" .. hand_name] = { "toggle_menu" }
			end
		end
		-- Vive controllers don't need special button bindings as they use touchpads

		-- Runs last so a mapping wins over the vanilla placements above
		add_mapped_buttons(hand_name, key_map)
	end)
end

-----------------------------------------
-- Advanced Controls Manager customisations --
-----------------------------------------
-- Applied last, after the "Button Mappings" menu above, so an input the player
-- rebound here keeps the actions they gave it.

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
