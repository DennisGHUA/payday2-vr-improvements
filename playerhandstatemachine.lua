--[[
	PlayerHandStateMachine

	Pass rotation into the hand state machines (position is done in Vanilla), so
	we don't have to use the unit's rotation (as it's a frame out of date).
--]]

function PlayerHandStateMachine:set_rotation(pos)
        self._rotation = pos
end

function PlayerHandStateMachine:rotation()
        return self._rotation or self:hand_unit():rotation()
end
