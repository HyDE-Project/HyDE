local item = { name = "Heat Shimmer", icon = "󰵢", description = "Subtle thermal shimmer" }
if not hl then return item end
hl.config({ decoration = { blur = { enabled = true, variant = "heat_shimmer", size = 9, passes = 2, glass = { refraction = 20.0, roughness = 0.75, size = 42.0 }, heat_shimmer = { speed = 1.2 } }, motion_blur = { enabled = true, samples = 6 } } })
return item
