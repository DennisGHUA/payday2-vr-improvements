--[[
	PlayerStandardVR

	Allow movement and rotation while not masked up
--]]

local old_update_check_actions = PlayerMaskOff._update_check_actions
function PlayerMaskOff:_update_check_actions(t, dt)
	-- _update_check_actions overwrites _move_dir, breaking movement
	local move_dir = self._move_dir -- Save
	old_update_check_actions(self, t, dt)
	self._move_dir = move_dir -- Load
end

-- Add rotation functionality to casing mode
local old_update = PlayerMaskOff.update
function PlayerMaskOff:update(t, dt)
	if old_update then
		old_update(self, t, dt)
	end
	
	-- Handle rotation in casing mode if available
	if PlayerStandardVR._rotation_exposed and PlayerStandardVR._do_rotation_function then
		PlayerStandardVR._do_rotation_function(self, t, dt)
	end
end
