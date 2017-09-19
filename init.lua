-- Reload config
function reloadConfig(paths)
	doReload = false
	for _,file in pairs(paths) do
		if file:sub(-4) == ".lua" then
			print("A lua file changed, doing reload")
			doReload = true
		end
	end
	if not doReload then
		print("No lua file changed, skipping reload")
		return
	end

	hs.reload()
	end

configFileWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig)
configFileWatcher:start()

-- Lock screen Mac OS X shortcut
hs.hotkey.bind({'cmd'}, 'L', function() hs.caffeinate.startScreensaver() end)

-- Mute on wake from sleep
function muteOnWake(eventType)
	if (eventType == hs.caffeinate.watcher.systemDidWake) then
		local output = hs.audiodevice.defaultOutputDevice()
		output:setMuted(true)
	end
end
caffeinateWatcher = hs.caffeinate.watcher.new(muteOnWake)
caffeinateWatcher:start()

local function directoryLaunchKeyRemap(mods, key, dir)
	local mods = mods or {}
	hs.hotkey.bind(mods, key, function()
		local shell_command = "open " .. dir
		hs.execute(shell_command)
	end)
end

directoryLaunchKeyRemap({'alt','shift'}, "E", "/Volumes")