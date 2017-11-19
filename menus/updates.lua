--[[
	Custom update system.

	Hook into BLT to download from our server. Not a very nice thing
	to do, but until I get a paydaymods account this is the easiest/quickest
	way.

	This is based around having a "custom_urls" tag in the update data, that
	should contain three items: check, patchnotes, and download

	These are URLs that are suffixed with the mod ID and used to fetch stuff.
]]

-- Print out hash for updating the server with
do
	local directory = Application:nice_path( ModPath, true )
	local hash = SystemFS:exists(directory) and file.DirectoryHash(directory) or nil
	log("[VRPlus] Update hash: " .. tostring(hash))
end

local function reload_updates()
	-- Mods get loaded before us, so patch in a new set of updates
	-- Nothing will have used the updates before this runs, though, so it's safe.
	for _, mod in pairs(BLT.Mods:Mods()) do
		for i, update in ipairs(mod.updates) do
			local update_data = mod.json_data["updates"][i]
			if update:GetId() == "vrplus" then -- Kinda cheating, FIXME
				local new_update = BLTUpdate:new( mod, update_data )
				mod.updates[i] = new_update
			end
		end
	end
end

-- BLTUpdate
local old_init = BLTUpdate.init
function BLTUpdate:init(parent_mod, data)
	old_init(self, parent_mod, data)
	self._custom_urls = data["custom_urls"]
end

local old_CheckForUpdates = BLTUpdate.CheckForUpdates
function BLTUpdate:CheckForUpdates( clbk )
	-- Unless the mod uses custom URLs, use the default one
	local data = self._custom_urls
	if not data then
		return old_CheckForUpdates(self, clbk)
	end

	-- Flag this update as already requesting updates
	self._requesting_updates = true

	-- Perform the request from the server
	local url = data.check .. self:GetId()
	dohttpreq( url, function( json_data, http_id )
		self:clbk_got_update_data( clbk, json_data, http_id )
	end)
end

local old_ViewPatchNotes = BLTUpdate.ViewPatchNotes
function BLTUpdate:ViewPatchNotes()
	-- Unless the mod uses custom URLs, use the default one
	local data = self._custom_urls
	if not data then
		return old_ViewPatchNotes(self)
	end

	local url = data.patchnotes .. self:GetId()
	if Steam:overlay_enabled() then
		Steam:overlay_activate( "url", url )
	else
		os.execute( "cmd /c start " .. url )
	end
end

-- BLTDownloadManager
local old_start_download = BLTDownloadManager.start_download
function BLTDownloadManager:start_download( update )
	-- Unless the mod uses custom URLs, use the default one
	local data = update._custom_urls
	if not data then
		return old_start_download(self, update)
	end

	-- Check if the download already going
	if self:get_download( update ) then
		log(string.format("[Downloads] Download already exists for %s (%s)", update:GetName(), update:GetParentMod():GetName()))
		return false
	end

	-- Check if this update is allowed to be updated by the download manager
	if update:DisallowsUpdate() then
		MenuCallbackHandler[ update:GetDisallowCallback() ]( MenuCallbackHandler )
		return false
	end

	-- Start the download
	local url = data.download .. update:GetId()
	local http_id = dohttpreq( url, callback(self, self, "clbk_download_finished"), callback(self, self, "clbk_download_progress") )

	-- Cache the download for access
	local download = {
		update = update,
		http_id = http_id,
		state = "waiting"
	}
	table.insert( self._downloads, download )

	return true
end

reload_updates()
