
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

directoryLaunchKeyRemap({'cmd','shift'}, "E", "/Volumes")

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

-- ALT+0 to }
-- (opt + keycode 9)
hs.hotkey.bind({'alt'}, '0', function()  hs.eventtap.keyStroke({"alt"}, 'SPACE') end)

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

-- Enable/Disable Keypress Show Mode with "C-⌘-⇧-p"
function showKeyPress(tap_event)
	local duration = 1.5  -- popup duration
	local modifiers = ""  -- key modifiers string representation
	local flags = tap_event:getFlags()
	local character = hs.keycodes.map[tap_event:getKeyCode()]
	-- we only want to read special characters via getKeyCode, so we
	-- use this subset of hs.keycodes.map
	local special_chars = {
		["f1"] = true, ["f2"] = true, ["f3"] = true, ["f4"] = true,
		["f5"] = true, ["f6"] = true, ["f7"] = true, ["f8"] = true,
		["f9"] = true, ["f10"] = true, ["f11"] = true, ["f12"] = true,
		["f13"] = true, ["f14"] = true, ["f15"] = true, ["f16"] = true,
		["f17"] = true, ["f18"] = true, ["f19"] = true, ["f20"] = true,
		["pad"] = true, ["pad*"] = true, ["pad+"] = true, ["pad/"] = true,
		["pad-"] = true, ["pad="] = true, ["pad0"] = true, ["pad1"] = true,
		["pad2"] = true, ["pad3"] = true, ["pad4"] = true, ["pad5"] = true,
		["pad6"] = true, ["pad7"] = true, ["pad8"] = true, ["pad9"] = true,
		["padclear"] = true, ["padenter"] = true, ["return"] = true,
		["tab"] = true, ["space"] = true, ["delete"] = true, ["escape"] = true,
		["help"] = true, ["home"] = true, ["pageup"] = true,
		["forwarddelete"] = true, ["end"] = true, ["pagedown"] = true,
		["left"] = true, ["right"] = true, ["down"] = true, ["up"] = true
	}
	
	-- if we have a simple character (no modifiers), we want a shorter
	-- popup duration.
	if (not flags.shift and not flags.cmd and
			not flags.alt and not flags.ctrl) then
		duration = 0.3
	end
	
	-- we want to get regular characters via getCharacters as it
	-- "cleans" the key for us (e.g. for a "⇧-5" keypress we want
	-- to show "⇧-%").
	if special_chars[character] == nil then
		character = tap_event:getCharacters(true)
		if flags.shift then
			character = string.lower(character)
		end
	end
	
	-- make some known special characters look good
	if character == "return" then
		character = "⏎"
	elseif character == "delete" then
		character = "⌫"
	elseif character == "escape" then
		character = "⎋"
	elseif character == "space" then
		character = "SPC"
	elseif character == "up" then
		character = "↑"
	elseif character == "down" then
		character = "↓"
	elseif character == "left" then
		character = "←"
	elseif character == "right" then
		character = "→"
	end
	
	-- get modifiers' string representation
	if flags.ctrl then
		modifiers = modifiers .. "C-"
	end
	if flags.cmd then
		modifiers = modifiers .. "⌘-"
	end
	if flags.shift then
		modifiers = modifiers .. "⇧-"
	end
	if flags.alt then
		modifiers = modifiers .. "⌥-"
	end
	
	-- actually show the popup
	hs.alert.show(modifiers .. character, duration)

end


local key_tap = hs.eventtap.new(
	{hs.eventtap.event.types.keyDown},
	showKeyPress
)

-- Enable/Disable Keypress Show Mode with "C-⌘-⇧-p"
k = hs.hotkey.modal.new({"cmd", "shift", "ctrl"}, 'P')
function k:entered()
	hs.alert.show("Enabling Keypress Show Mode", 1.5)
	key_tap:start()
end
function k:exited()
	hs.alert.show("Disabling Keypress Show Mode", 1.5)
end
k:bind({"cmd", "shift", "ctrl"}, 'P', function()
	key_tap:stop()
	k:exit()
end)