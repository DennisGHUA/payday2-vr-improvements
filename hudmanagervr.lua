--[[
	HUDManagerVR

	Set a speedup effect when the heist ends
]]

Hooks:PostHook(HUDManager, "setup_endscreen_hud", "VRPlusSpeedUpEndscreen", function(self)
	local speedup = VRPlusMod._data.tweaks and VRPlusMod._data.tweaks.endscreen_speedup or 1
	if self._hud_stage_endscreen then
		self._hud_stage_endscreen:set_speed_up(speedup)
	end
end)

-- Total replacement of the tablet GUI to add a new panel
function HUDManagerVR:_init_tablet_gui()
	self._tablet_ws = self._gui:create_world_workspace(402, 226, Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0))
	local tablet_panel = self._tablet_ws:panel()
	local main = tablet_panel:panel({
		name = "main_page"
	})
	local right = tablet_panel:panel({
		name = "right_page",
		x = tablet_panel:w()
	})
	local left = tablet_panel:panel({
		name = "left_page",
		x = -tablet_panel:w()
	})
	local left2 = tablet_panel:panel({
		name = "left2_page",
		x = -tablet_panel:w() * 2
	})
	self._tablet_highlight = tablet_panel:panel({
		layer = 10,
		name = "highlight"
	})

	self._tablet_highlight:bitmap({
		texture = "guis/dlcs/vr/textures/pd2/pad_state_rollover",
		name = "highlight",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})

	self._tablet_touch = self._tablet_highlight:bitmap({
		texture = "guis/dlcs/vr/textures/pd2/pad_state_touch",
		name = "highlight",
		h = 100,
		w = 100
	})

	self._tablet_highlight:hide()
	
	-- Manually add the backgrounds because of duplicate texture keys
	main:bitmap({
		name = "bg",
		layer = -2,
		texture = "guis/dlcs/vr/textures/pd2/pad_bg",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})
	left:bitmap({
		name = "bg",
		layer = -2,
		texture = "guis/dlcs/vr/textures/pd2/pad_bg",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})
	left2:bitmap({
		name = "bg",
		layer = -2,
		texture = "guis/dlcs/vr/textures/pd2/pad_bg_r",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})
	right:bitmap({
		name = "bg",
		layer = -2,
		texture = "guis/dlcs/vr/textures/pd2/pad_bg_l",
		w = tablet_panel:w(),
		h = tablet_panel:h()
	})

	self._page_panels = {
		main,
		right,
		left,
		left2
	}
	self._pages = {
		main = {
			left = "left",
			right = "right"
		},
		right = {
			left = "main"
		},
		left = {
			left = "left2",
			right = "main"
		},
		left2 = {
			right = "left"
		}
	}
	self._current_page = "main"
	self._page_callbacks = {
		on_interact = {},
		on_focus = {}
	}
	
	self:_init_vrplus_voicepanel(left2)

	if VRPlusMod and VRPlusMod._data and VRPlusMod._data.hud and VRPlusMod._data.hud.tablet_heist_info then
		self:_init_vrplus_heist_panel(main)
	end

	self._tablet_ws:hide()
end

function HUDManagerVR:_init_vrplus_heist_panel(page_panel)

	-- Add Heist Info to main page (horizontal layout in the middle)
	self._vrplus_heist_panel = page_panel:panel({
		name = "vrplus_stealth_panel",
		w = 270,
		h = 30,
		x = (page_panel:w() / 2) - 135, -- Centered to accommodate 4 items + tri-loot
		y = 115, -- Between objectives and teammates
		layer = 10
	})
	
	local function add_icon_and_text(panel, icon_name, x_offset, y_offset, text_name)
		local texture, texture_rect = tweak_data.hud_icons:get_icon_data(icon_name)
		-- Provide a fallback texture just in case
		if not texture then
			texture = "guis/textures/pd2/none_icon"
			texture_rect = {0, 0, 32, 32}
		end
		
		panel:bitmap({
			name = text_name .. "_icon",
			texture = texture,
			texture_rect = texture_rect,
			w = 20,
			h = 20,
			x = x_offset,
			y = y_offset + 1,
			layer = 1
		})
		
		return panel:text({
			name = text_name,
			text = "0",
			font = tweak_data.hud.medium_font_noshadow,
			font_size = 22,
			color = Color.white,
			x = x_offset + 25,
			y = y_offset,
			layer = 1
		})
	end

	local function add_raw_icon_and_text(panel, raw_texture, raw_rect, x_offset, y_offset, text_name)
		panel:bitmap({
			name = text_name .. "_icon",
			texture = raw_texture,
			texture_rect = raw_rect,
			w = 20,
			h = 20,
			x = x_offset,
			y = y_offset + 1,
			layer = 1
		})
		return panel:text({
			name = text_name,
			text = "0",
			font = tweak_data.hud.medium_font_noshadow,
			font_size = 22,
			color = Color.white,
			x = x_offset + 25,
			y = y_offset,
			layer = 1
		})
	end

	self._vrplus_pager_text = add_icon_and_text(self._vrplus_heist_panel, "pagers_used", 0, 0, "pager_text")
	-- Skull body bag icon from the skill tree atlas (row 11, col 5, 64x64 tiles)
	self._vrplus_bodybag_text = add_raw_icon_and_text(self._vrplus_heist_panel, "guis/textures/pd2/skilltree/icons_atlas", {5*64, 11*64, 64, 64}, 50, 0, "bodybag_text")
	self._vrplus_guard_text = add_icon_and_text(self._vrplus_heist_panel, "minions_converted", 100, 0, "guard_text")

	-- Loot icon for the tri-loot display
	local loot_texture, loot_texture_rect = tweak_data.hud_icons:get_icon_data("wp_bag")
	if not loot_texture then
		loot_texture = "guis/textures/pd2/none_icon"
		loot_texture_rect = {0, 0, 32, 32}
	end
	self._vrplus_heist_panel:bitmap({
		name = "loot_icon",
		texture = loot_texture,
		texture_rect = loot_texture_rect,
		w = 20,
		h = 20,
		x = 150,
		y = 1,
		layer = 1
	})
	-- Unbagged (red) / Bagged (yellow) / Secured (green)
	self._vrplus_loot_unbagged_text = self._vrplus_heist_panel:text({
		name = "loot_unbagged",
		text = "0",
		font = tweak_data.hud.medium_font_noshadow,
		font_size = 22,
		color = Color(1, 0.25, 0.25), -- red
		x = 175,
		y = 0,
		layer = 1
	})
	self._vrplus_heist_panel:text({
		name = "loot_sep1",
		text = "/",
		font = tweak_data.hud.medium_font_noshadow,
		font_size = 22,
		color = Color.white,
		x = 196,
		y = 0,
		layer = 1
	})
	self._vrplus_loot_bagged_text = self._vrplus_heist_panel:text({
		name = "loot_bagged",
		text = "0",
		font = tweak_data.hud.medium_font_noshadow,
		font_size = 22,
		color = Color(1, 0.9, 0.2), -- yellow
		x = 205,
		y = 0,
		layer = 1
	})
	self._vrplus_heist_panel:text({
		name = "loot_sep2",
		text = "/",
		font = tweak_data.hud.medium_font_noshadow,
		font_size = 22,
		color = Color.white,
		x = 226,
		y = 0,
		layer = 1
	})
	self._vrplus_loot_secured_text = self._vrplus_heist_panel:text({
		name = "loot_secured",
		text = "0",
		font = tweak_data.hud.medium_font_noshadow,
		font_size = 22,
		color = Color(0.3, 1, 0.3), -- green
		x = 235,
		y = 0,
		layer = 1
	})
end

function HUDManagerVR:_init_vrplus_voicepanel(voice_panel)

	-- Rows and columns of voice lines
	self._voice_ids = {
		{
			{ id = "v56", name = "Hello" }, -- Hello
			{ id = "g15", name = "Over There" }, -- There/Look
			{ id = "v32", name = "Over Here" } -- Here it is
		},
		{
			{ id = "v46", name = "Yes" }, -- Yes
			{ id = "s05x_sin", name = "Thanks" }, -- Thanks
			{ id = "g11", name = "No" } -- No/Wrong
		},
		{
			{ id = "f38_any", name = "Follow me" }, -- Follow Me
			{ id = "g16", name = "Keep defending" }, -- Keep Defending
			{ id = "g17", name = "Time to go" } -- Time To Go
		}
	}
	
	self._voice_width = voice_panel:w()
	self._voice_height = voice_panel:h()
	
	self._voice_subpanels = {}
	
	local i = 0 -- X
	local j = 0 -- Y
	
	for row, data in ipairs(self._voice_ids) do
		i = 0
		for column, voice_data in ipairs(data) do
			local btn_panel = voice_panel:panel({
				name = voice_data.id,
				alpha = 1,
				x = (self._voice_width / 3) * i,
				y = (self._voice_height / 3) * j,
				w = self._voice_width / 3,
				h = self._voice_height / 3
			})
			
			btn_panel:bitmap({
				name = "bg",
				layer = -1,
				texture = "guis/textures/pd2/box_bg",
				w = btn_panel:w(),
				h = btn_panel:h()
			})
			
			btn_panel:text({
				x = 0,
				y = 0,
				name = "text_" .. voice_data.id,
				vertical = "center",
				hvertical = "center",
				align = "center",
				blend_mode = "normal",
				halign = "center",
				layer = 2,
				text = voice_data.name,
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = Color.white
			})
			
			table.insert(self._voice_subpanels, btn_panel)
			
			i = i + 1
		end
		
		j = j + 1
	end
	
	self:add_page_callback("left2", "on_interact", callback(self, self, "_on_voicepanel_interact"))
end

function HUDManagerVR:_on_voicepanel_interact(position)	
	-- Get X and Y, but remap them from -1,1 to 0,1
	local x = (position.x * 0.5) + 0.5
	local y = (position.y * 0.5) + 0.5
	
	-- Convert X and Y to 1, 2 or 3
	x = math.ceil(x * 3)
	y = math.ceil(y * 3)
	
	-- Speak chosen line
	self:_voice_speak(self._voice_ids[y][x].id)
end

function HUDManagerVR:_voice_speak(voice_id)

	-- 2 sec cooldown, disallow voice spam
	if self._last_speak_t and managers.player:player_timer():time() - self._last_speak_t < 2 then
		return
	end

	if Utils:IsInHeist() and Utils:IsInCustody() == false and Utils:IsInGameState() then
		managers.player:local_player():sound():say(voice_id, true, true)
		self._last_speak_t = managers.player:player_timer():time()
	end
end

Hooks:PostHook(HUDManager, "update", "VRPlusHeistInfo", function(self, t, dt)
	-- Skip entirely when the tablet heist info is disabled in the mod menu
	if not VRPlusMod or not VRPlusMod._data or not VRPlusMod._data.hud or not VRPlusMod._data.hud.tablet_heist_info then
		return
	end

	-- Throttle updates to avoid iterating enemies every single frame (update twice a second)
	if not Utils:IsInHeist() or not Utils:IsInGameState() then return end
	self._vrplus_update_t = self._vrplus_update_t or t
	if t - self._vrplus_update_t < 0.5 then
		return
	end
	self._vrplus_update_t = t

	local hudvr = self
	if hudvr and hudvr._vrplus_pager_text then

		-- Update Pagers (Counting up instead of down)
		local pagers_used = managers.groupai and managers.groupai:state() and managers.groupai:state():get_nr_successful_alarm_pager_bluffs() or 0
		hudvr._vrplus_pager_text:set_text(tostring(pagers_used))

		-- Update Body Bags
		local body_bags = managers.player and managers.player:get_body_bags_amount() or 0
		hudvr._vrplus_bodybag_text:set_text(tostring(body_bags))

		-- Update Guards
		local guards = 0
		if managers.enemy then
			for u_key, u_data in pairs(managers.enemy:all_enemies()) do
				-- Safely check unit_data to prevent crashes
				if alive(u_data.unit) and u_data.unit:unit_data() then
					local ud = u_data.unit:unit_data()
					if ud and ud.has_alarm_pager then
						guards = guards + 1
					end
				end
			end
		end
		hudvr._vrplus_guard_text:set_text(tostring(guards))

		-- Update Secured Loot
		local secured_loot = 0
		if managers.loot then
			secured_loot = (managers.loot:get_secured_mandatory_bags_amount() or 0) + (managers.loot:get_secured_bonus_bags_amount() or 0)
		end

		-- Count unbagged / bagged loot on the map
		local total_unbagged = 0
		local total_bagged = 0
		if managers.interaction and managers.interaction._interactive_units then
			for _, unit in pairs(managers.interaction._interactive_units) do
				if alive(unit) and unit:carry_data() then
					local carry_id = unit:carry_data():carry_id()
					local tweak_entry = tweak_data.carry[carry_id]
					if tweak_entry and not tweak_entry.is_vehicle and not tweak_entry.skip_exit_secure then
						if carry_id ~= "person" or (managers.job and managers.job:current_level_id() == "mad") then
							-- Bagged loot is any dropped carry bag that can be picked up again.
							-- Standard bags use tweak_data "carry_drop", but some have their own variant
							-- (e.g. paintings use "painting_carry_drop"), just match the common suffix.
							local interact_id = unit:interaction() and unit:interaction().tweak_data
							if interact_id and string.find(interact_id, "carry_drop", 1, true) then
								total_bagged = total_bagged + 1
							else
								total_unbagged = total_unbagged + 1
							end
						end
					end
				end
			end
		end

		if hudvr._vrplus_loot_unbagged_text then
			hudvr._vrplus_loot_unbagged_text:set_text(tostring(total_unbagged))
			hudvr._vrplus_loot_bagged_text:set_text(tostring(total_bagged))
			hudvr._vrplus_loot_secured_text:set_text(tostring(secured_loot))
		end
	end
end)
