local item = {name = "Aurora", icon = "󰵢", description = "Aurora-like light streaks"}
if not hl then
    return item
end
hl.config(
    {
        decoration = {
            blur = {
                enabled = true,
                variant = "aurora",
                size = 9,
                passes = 2,
                vibrancy = 0.22,
                glass = {refraction = 18.0, roughness = 0.82, size = 48.0},
                aurora = {color1 = "0x2CF4A7FF", color2 = "0x8A57FFFF", intensity = 0.42, speed = 1.3}
            }
        }
    }
)
return item
