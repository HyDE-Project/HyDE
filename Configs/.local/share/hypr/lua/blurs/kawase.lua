local item = { name = "Kawase", icon = "󰵢", description = "Classic Kawase blur" }
if not hl then return item end
hl.config({ decoration = { blur = { enabled = true, variant = "kawase", size = 9, passes = 2, contrast = 0.9, vibrancy = 0.2, noise = 0.012 } } })
return item
