--[[
	TimeSpeedEffectTweakData

	Disable slow-motion (eg, when downed) in VR, as being helped up while in slow
	motion causes automatic weapons to fire much faster than they should, and
	breaks semi-automatic weapons

	This was based off the slow motion disabler in WolfHUD
--]]

if not _G.VR then return end

Hooks:PostHook(TimeSpeedEffectTweakData, "init", "VRPlusRemoveSlowMotion", function(self, ...)
	local function disable_effect(data)
		if data.speed and data.sustain then
			data.speed = 1
			data.fade_in_delay = 0
			data.fade_in = 0
			data.sustain = 0
			data.fade_out = 0
		elseif type(data) == "table" then
			for _, val in pairs(data) do
				disable_effect(val)
			end
		end
	end

	disable_effect(self)
end)
