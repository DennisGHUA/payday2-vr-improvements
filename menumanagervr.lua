--[[
	MenuManagerVR

	Hide the redout effect when entering the menu
--]]

-- When the user opens the menu, hide the redout effect
Hooks:PostHook(MenuManagerVR, "_enter_menu_room", "VRPlusOpenMenuHideRedout", function()
	local r = FPCameraPlayerBase.__redout
	if r then
		r.effect.color.alpha = 0
	end
end)

-- Don't need to reapply it - it's computed each tick in FPCameraPlayerBase
