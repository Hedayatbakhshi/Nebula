-- Nebula shell — autostart additions
-- Add these lines inside the hl.on("hyprland.start", ...) block
-- in your ~/.config/hypr/lua/autostart.lua (or equivalent).

-- Starts the shell, plus awww-daemon and the cliphist watcher if they aren't running
hl.exec_cmd("~/.local/bin/nebula start")
