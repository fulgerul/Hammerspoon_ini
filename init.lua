
-- disable animations
hs.window.animationDuration = 0

-- hide window shadows
hs.window.setShadows(false)

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

-- Open Explorer Win+E
local function directoryLaunchKeyRemap(mods, key, dir)
	local mods = mods or {}
	hs.hotkey.bind(mods, key, function()
		local shell_command = "open " .. dir
		hs.execute(shell_command)
	end)
end

directoryLaunchKeyRemap({'alt','shift'}, "E", "/Volumes")

-- Cmd + Tab
switcher = require "hs.window.switcher"
filter = require "hs.window.filter"
switcher = switcher.new(filter.new():setDefaultFilter{}, {
	selectedThumbnailSize = 288,
	thumbnailSize         = 128,
	showTitles            = false,
	textSize              = 11,
	textColor             = { 1.0, 1.0, 1.0, 0.75 },
	backgroundColor       = { 0.3, 0.3, 0.3, 0.75 },
	highlightColor        = { 0.8, 0.5, 0.0, 0.80 },
	titleBackgroundColor  = { 0.0, 0.0, 0.0, 0.75 },
})
hs.hotkey.bind('alt', 'tab', function() switcher:next() end)
hs.hotkey.bind('alt-shift', 'tab', function() switcher:previous() end)

---- Battery
local imagePath =  os.getenv("HOME") .. '/.hammerspoon/img/';

local battery = {
	rem = hs.battery.percentage(),
	source = hs.battery.powerSource(),
	icon = imagePath ..'battery-charging.pdf',
	title =  "Battery Status",
	sound = "Sosumi",
	min = 50,
	showPercentage = false -- Bugged, show multiple copies..
}


-- notify when battery is full
function notifyWhenBatteryFullyCharged()
	local currentPercentage = hs.battery.percentage()
	if currentPercentage == 100  and battery.rem ~= currentPercentage and battery.source == 'AC Power' then
		battery.rem = currentPercentage
		hs.notify.new({
			title        = battery.title,
			subTitle     = 'Charged completely!',
			contentImage = battery.icon,
			soundName    = battery.sound
		}):send()
	end
end


-- notify when battery is less than battery.min
function notifyWhenBatteryLow()
	local currentPercentage = hs.battery.percentage()
	if currentPercentage <= battery.min and battery.rem ~= currentPercentage and (currentPercentage % 5 == 0 ) then
		battery.rem = currentPercentage
		hs.notify.new({
			title        = battery.title,
			informativeText     = 'Battery left: '..battery.rem.."%\nPower Source: "..battery.source,
			contentImage = battery.icon,
			soundName    = battery.sound
		}):send()
	end
end



-- alert battery source when it changes
function alertPowerSource()
	local currentPowerSource= hs.battery.powerSource()
	if battery.source ~= currentPowerSource then
		battery.source = currentPowerSource
		hs.alert.show(battery.source);
	end
end



-- display battery percentage on menu bar
function showPercentageonNavbar()
	local menuItem = hs.menubar.new(true)
	local currentPercentage = hs.battery.percentage()
	local remBatteryString = string.format("%.0f", currentPercentage)
	menuItem:setTitle(remBatteryString.."%")
end



function watchBattery()
	if battery.showPercentage then
		showPercentageonNavbar()
	end
	alertPowerSource()
	notifyWhenBatteryLow()
	notifyWhenBatteryFullyCharged()
end


-- start watching
hs.battery.watcher.new(watchBattery):start()

