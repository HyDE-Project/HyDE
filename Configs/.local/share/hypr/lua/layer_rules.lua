-- # // █░░ ▄▀█ █▄█ █▀▀ █▀█   █▀█ █░█ █░░ █▀▀ █▀
-- # // █▄▄ █▀█ ░█░ ██▄ █▀▄   █▀▄ █▄█ █▄▄ ██▄ ▄█

local util = _G.hyde.utils

local layers =
  util.regex_compile(
  {
    namespace = {
      "rofi",
      "notifications",
      "swaync-(notification-window|control-center)",
      "waybar",
      "logout_dialog"
    }
  },
  true
)

local ignore_alpha_layers =
  util.regex_compile(
  {
    namespace = {
      "rofi",
      "notifications",
      "swaync-(notification-window|control-center)",
      "logout_dialog",
      "waybar",
      "selection"
    }
  },
  true
)

hl.layer_rule(
  {
    name = "hyde_layer_blur",
    match = {namespace = layers.namespace},
    blur = true
  }
)

hl.layer_rule(
  {
    name = "hyde_layer_ignore_alpha",
    match = {namespace = ignore_alpha_layers.namespace},
    ignore_alpha = true
  }
)

hl.layer_rule(
  {
    name = "hyde_layer_no_anim",
    no_anim = true,
    match = {namespace = "selection"}
  }
)
