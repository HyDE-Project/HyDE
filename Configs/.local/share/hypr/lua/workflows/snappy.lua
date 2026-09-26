local workflow = {
  name = "Snappy",
  icon = "󰓅",
  description = "A snappy desktop with no animations and effects, but preserving readability",
}

if not hl then
  return workflow
end

hl.config({
  decoration = {
    rounding = 0,
  },
  general = {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 1,
  },
  animations = {
    enabled = false,
  },
})
