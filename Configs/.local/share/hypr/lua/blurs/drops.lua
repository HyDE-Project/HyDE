local item = {name = "Drops", icon = "󰵢", description = "Rain-on-glass effect"}
if not hl then
    return item
end
hl.config(
    {
        decoration = {
            blur = {
                enabled = true,
                variant = "drops",
                size = 10,
                passes = 2,
                contrast = 0.95,
                noise = 0.015,
                glass = {refraction = 20.0, roughness = 0.9, size = 44.0},
                drops = {speed = 3.2}
            }
        }
    }
)
return item
