local item = { name = "Prism", icon = "󰵢", description = "Triangular refraction mask" }
if not hl then return item end
hl.config({ decoration = { blur = { enabled = true, variant = "prism", size = 10, passes = 2, vibrancy = 0.26, glass = { refraction = 20.0, roughness = 0.95, size = 38.0 } }, glow = { enabled = true, range = 14, render_power = 3, color = "0x99A9EEFF", color_inactive = "0x5599A9FF" } } })
return item
