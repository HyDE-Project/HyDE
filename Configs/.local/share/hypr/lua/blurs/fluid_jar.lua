local item = {name = "Fluid Jar", icon = "󰵢", description = "2D fluid simulation"}
if not hl then
    return item
end
hl.config(
    {
        decoration = {
            blur = {
                enabled = true,
                variant = "fluid_jar",
                size = 9,
                passes = 2,
                contrast = 0.93,
                fluid_jar = {
                    color = "0xCC4AA9FF",
                    speed = 4.0,
                    fill_amount = 0.56,
                    turbulence = 1.3,
                    distortion = 8.5,
                    mass = 1.5,
                    precision = 2.0
                }
            },
            wobble = {enabled = true, intensity = 0.14, damping = 14, stiffness = 220}
        }
    }
)
return item
