
Hooks:PreHook(WarpTargetState, "transition", "VRPlusWarpOnRelease", function(self)
	if not VRPlusMod._data.teleport_on_release then return end

	local targeting = self.params.input:state().warp_target

	if not targeting and self.__touch_warp_last then
		self.params.input:state().warp_target = true
		self.params.input:state().warp = true
		self.params.input._is_movement_warp = true
	end

	self.__touch_warp_last = targeting
end)
