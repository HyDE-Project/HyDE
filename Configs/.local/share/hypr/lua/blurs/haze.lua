local item = { name = "Haze", icon = "󰵢", description = "Diffused pearlescent haze" }
if not hl then return item end
hl.config({ decoration = { blur = { enabled = true, variant = "haze", size = 10, passes = 3, brightness = 1.01, contrast = 0.9, vibrancy = 0.21, haze = { intensity = 0.38, iridescence = 0.78 } } } })
return item
