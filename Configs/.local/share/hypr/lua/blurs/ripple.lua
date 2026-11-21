local item = { name = "Ripple", icon = "󰵢", description = "Pointer ripple waves" }
if not hl then return item end
hl.config({ decoration = { blur = { enabled = true, variant = "ripple", size = 9, passes = 2, ripple = { radius = 420.0, strength = 30.0, width = 34.0, duration = 0.5 } } } })
return item
