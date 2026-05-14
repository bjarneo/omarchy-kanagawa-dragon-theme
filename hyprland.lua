local active_border_color = "rgb(545464)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
    },
  },
})

-- Kanagawa Lotus backdrop is light; keep terminals near-opaque so text stays legible.
hl.window_rule({ match = { tag = "terminal" }, opacity = "0.98 0.95" })
