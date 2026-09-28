-- Monitor and workspace configuration
-- ~/.config/hypr/lua/monitor.lua
-- `hyprctl monitors` lists your output names.

-- Every monitor at its preferred mode, placed automatically
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Pin a specific output like this:
-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- And send workspaces to it like this:
-- hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
