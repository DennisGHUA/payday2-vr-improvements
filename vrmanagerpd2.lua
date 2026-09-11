
-- Stutter fix for the Diesel 3.0 (update 247) engine upgrade:
-- the vanilla _update_adaptive_quality_level re-applies the output scaling and re-sizes the
-- adaptive viewports every single VR frame, chasing the engine's frequently-recomputed
-- quality level. Every re-apply re-allocates the render targets (a full graphics pipeline
-- flush), which froze the game every few seconds.
--
-- The vanilla calls are still made - they configure the desktop-mirror view - but only
-- once at the start of the VR session, and again only when the values actually change,
-- debounced. The desktop window keeps showing the same single view as vanilla, while the
-- per-frame churn (the freeze) is gone. Force quality off is pinned at the default 1:1.

local STUTTER_FIX_DEBOUNCE = 0.5

local last_quality_level
local last_applied_x
local last_applied_y
local next_apply_t

function VRManagerPD2:_update_adaptive_quality_level(t, ...)
	if self._update_super_sample_scale_t and self._update_super_sample_scale_t < t then
		self._update_super_sample_scale_t = nil
	end

	-- Force quality off: pinned to the default 1:1 instead of following the engine's
	-- per-frame adaptive level (following that level is exactly the freeze).
	local force_enabled = VRPlusMod._data.tweaks.force_quality_enable and true or false
	local quality_level = 7

	if force_enabled then
		quality_level = math.floor(VRPlusMod._data.tweaks.force_quality + 0.5)
		quality_level = math.clamp(quality_level, 1, 7)
	end

	local quality_changed = quality_level ~= last_quality_level

	local scale = VRManager:super_sample_scale()

	if (math.abs(scale - self._super_sample_scale) > 0.01 or quality_changed)
			and not self._update_super_sample_scale_t then
		self._update_super_sample_scale_t = t + 0.5
		self._super_sample_scale = scale

		Application:apply_render_settings()
	end

	if quality_changed then
		last_quality_level = quality_level
	end

	local x_scale = 1
	local y_scale = 1

	if quality_level < 7 then
		local tres = VRManager:target_resolution()
		local scaling = self._adaptive_scale[quality_level]
		x_scale = scaling / self._adaptive_scale_max
		local res_x = math.floor(tres.x * x_scale)

		if res_x % 4 > 0.01 then
			res_x = res_x + 4 - res_x % 4
		end

		x_scale = res_x / tres.x + 0.05 / tres.x
		y_scale = scaling / self._adaptive_scale_max
		local res_y = math.floor(tres.y * y_scale)

		if res_y % 2 > 0.01 then
			res_y = res_y + 1
		end

		y_scale = res_y / tres.y + 0.05 / tres.y
	end

	-- Only apply when the effective values changed, at most once per debounce window.
	-- The original code ran these every frame (the freeze); the first call at the start of
	-- the VR session is what keeps the desktop mirror showing the correct single view.
	if (x_scale ~= last_applied_x or y_scale ~= last_applied_y)
			and (not next_apply_t or t >= next_apply_t) then
		next_apply_t = t + STUTTER_FIX_DEBOUNCE
		last_applied_x = x_scale
		last_applied_y = y_scale

		VRManager:set_output_scaling(x_scale, y_scale)
		managers.overlay_effect:viewport():set_dimensions(0, 0, x_scale, y_scale)

		for _, svp in ipairs(managers.viewport:all_really_active_viewports()) do
			if svp:use_adaptive_quality() then
				svp:vp():set_dimensions(0, 0, x_scale, y_scale)
			end
		end

		for _, svp in ipairs(self._viewports) do
			if svp:use_adaptive_quality() then
				svp:vp():set_dimensions(0, 0, x_scale, y_scale)
			end
		end
	end
end
