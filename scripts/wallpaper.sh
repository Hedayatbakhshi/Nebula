#!/bin/bash
wallpaper="$1"
scheme="$2"
theme="${3,,}"
transition="${4:-fade}"
gowall="${5:-off}"
gowall_icons="${6:-off}"
invert="${7:-off}"
gowall_shell="${8:-off}"

SCRIPTS="$HOME/.config/quickshell/scripts"
GOWALL="$SCRIPTS/gowall_theme.py"
display="$wallpaper"

palette_on=false
[ -n "$gowall" ] && [ "${gowall,,}" != "off" ] && [ "${gowall,,}" != "none" ] && palette_on=true
invert_on=false
[ "${invert,,}" = "on" ] && invert_on=true
$invert_on && inv="--invert"

icons_on=false
$palette_on && [ "${gowall_icons,,}" = "on" ] && icons_on=true
$icons_on && keep_icons="--keep-icon-theme"

# The shell's own colors can come from the palette instead of the wallpaper.
# "match" is the shell's palette already, so it has nothing to take from.
shell_on=false
$palette_on && [ "${gowall_shell,,}" = "on" ] && [ "${gowall,,}" != "match" ] && shell_on=true
if $shell_on; then
    palette_file=$(python3 "$GOWALL" --palette "$gowall" | tail -n1)
    [ -f "$palette_file" ] && pal="--palette-file $palette_file"
fi

show() {
    awww img "$1" --transition-type "$transition" --transition-duration 4
}

if $palette_on && [ "${gowall,,}" = "match" ]; then
    # The palette has to exist before gowall can be pointed at it, so colors come
    # from the untouched wallpaper and only the image is recolored.
    python3 "$SCRIPTS/gen_colors.py" "$wallpaper" "$scheme" "$theme" $keep_icons
    converted=$(python3 "$GOWALL" "$wallpaper" match $inv | tail -n1)
    [ -f "$converted" ] && display="$converted"
    show "$display"
    python3 "$SCRIPTS/gen_colors.py" "$wallpaper" "$scheme" "$theme" --display "$display" $keep_icons
elif $palette_on || $invert_on; then
    converted=$(python3 "$GOWALL" "$wallpaper" "$gowall" $inv | tail -n1)
    [ -f "$converted" ] && display="$converted"
    show "$display"
    python3 "$SCRIPTS/gen_colors.py" "$display" "$scheme" "$theme" --source "$wallpaper" $keep_icons $pal
else
    show "$display"
    python3 "$SCRIPTS/gen_colors.py" "$wallpaper" "$scheme" "$theme"
fi

$icons_on && python3 "$SCRIPTS/gowall_icons.py" "$gowall" --apply
exit 0
