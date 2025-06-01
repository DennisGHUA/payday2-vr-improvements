--[[
	MeleeRotation
	
	Ensures that rotation works when the player is using a melee weapon
	
	NOTE: This file is now deprecated and has been integrated directly into handmelee.lua
	      to fix startup crashes. The code remains here for reference only.
]]

-- Make sure MeleeHandState exists before hooking
if not _G.MeleeHandState then
    -- If the class doesn't exist yet, set up a delayed hook
    Hooks:Add("SetupPlayerMovementState", "VRPlusMeleeRotationDelayed", function()
        if _G.MeleeHandState then
            -- Add a hook to the melee state to enable rotation
            Hooks:PostHook(MeleeHandState, "apply", "VRPlusMeleeRotation", function(self, hand, key_map)
                if not VRPlusMod or not VRPlusMod._data or not VRPlusMod._data.turning_mode or VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

                local hand_name = hand == 1 and "r" or "l"

                -- Enable rotation during melee by mapping the dpad input to touchpad_primary
                key_map["dpad_" .. hand_name] = { "touchpad_primary" }
            end)
        end
    end)
else
    -- If the class already exists, hook directly
    Hooks:PostHook(MeleeHandState, "apply", "VRPlusMeleeRotation", function(self, hand, key_map)
        if not VRPlusMod or not VRPlusMod._data or not VRPlusMod._data.turning_mode or VRPlusMod._data.turning_mode == VRPlusMod.C.TURNING_OFF then return end

        local hand_name = hand == 1 and "r" or "l"

        -- Enable rotation during melee by mapping the dpad input to touchpad_primary
        key_map["dpad_" .. hand_name] = { "touchpad_primary" }
    end)
end
