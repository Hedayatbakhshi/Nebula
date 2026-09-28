local M = {}
<* for name, value in colors *>
M.{{name}} = "rgba({{value.default.hex_stripped}}ff)"
<* endfor *>
M.active_border   = "rgba({{colors.primary.default.hex_stripped}}ff)"
M.inactive_border = "rgba({{colors.outline_variant.default.hex_stripped}}ff)"

return M
