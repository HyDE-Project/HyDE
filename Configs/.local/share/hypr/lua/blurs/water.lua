local item = { name = "Water", icon = "󰵢", description = "Heightmap ripple water" }
if not hl then return item end
hl.config({ decoration = { blur = { enabled = true, variant = "water", size = 9, passes = 2, water = { speed = 0.82, strength = 32.0, radius = 24.0, damping = 0.94, duration = 14.0 } } } })
return item
