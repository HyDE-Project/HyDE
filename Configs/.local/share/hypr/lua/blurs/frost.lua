local item = {name = "Frost", icon = "󰵢", description = "Cracked ice frost"}
if not hl then
    return item
end
hl.config(
    {
        decoration = {
            blur = {
                enabled = true,
                variant = "frost",
                size = 11,
                passes = 3,
                brightness = 0.98,
                contrast = 0.88,
                vibrancy = 0.12,
                glass = {refraction = 16.0, roughness = 1.0, size = 36.0}
            },
            shadow = {color = "0x99000000", color_inactive = "0x44000000"}
        }
    }
)
return item
