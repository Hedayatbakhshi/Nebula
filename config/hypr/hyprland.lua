-- Hyprland Lua Configuration (Nebula requires Hyprland >= 0.56 with this Lua config)
-- Entry point — loads all modules in order
-- ~/.config/hypr/hyprland.lua

require("lua.environment") -- env vars must come first
require("lua.colors")      -- written by nebula from your wallpaper (used by settings)
require("lua.monitor")     -- monitor + workspace assignments
require("lua.autostart")   -- exec-once startup programs
require("lua.settings")    -- general, decoration, input, misc, layouts
require("lua.animations")  -- bezier curves + animations
require("lua.keybinds")    -- key bindings
require("lua.rules")       -- window / layer rules
