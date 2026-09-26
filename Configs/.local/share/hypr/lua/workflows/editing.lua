local workflow = {
  name = "Editing",
  icon = "",
  description = "Best for writing and editing. Disables window transparency",
}

if not hl then
  return workflow
end

hl.config({
  decoration = {
    active_opacity = 1,
    inactive_opacity = 1,
    fullscreen_opacity = 1,
  },
})

hl.window_rule({
  opaque = true,
  match = {
    class = ".*",
  },
})
